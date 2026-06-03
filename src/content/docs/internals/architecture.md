---
title: Architecture
description: How the runtime is structured — the server layer, WebSocket protocol, session management, role turns, and operator events.
---

> These pages describe the current implementation. They may lag behind code changes.

The runtime is a Node.js process with two communication surfaces: an HTTP server (for the React UI's static assets and REST endpoints) and a WebSocket server (for all live orchestration traffic). Everything flows through the WebSocket.

```
Browser UI
    │  WebSocket (ws://)
    ▼
server.ts  ──► SocketHub
    │
    ▼
RuntimeSessionManager
    ├── FlowOrchestrator          (forward pass)
    ├── ImprovementOrchestrator   (backward pass)
    └── ConsentGateImpl           (tool permission gate)
```

---

## Server layer (`server.ts`)

`buildServer` wires together:

- **Express** — serves the compiled React UI via `registerStaticUi` and REST endpoints via `registerFlowRoutes` and `registerSettingsRoutes`
- **`http.Server`** — wraps Express so the WebSocket server can share the same port
- **`WebSocketServer`** — one connection per browser tab; handled in `wss.on('connection')`
- **`SocketHub`** — tracks all open sockets and their flow subscriptions
- **`createFlowReadModel`** — a thin read layer over `SessionStore` used for non-mutating reads
- **`createRuntimeSessionManager`** — owns all live orchestration state

On connection, the server sends an `init` message with the current project list. Every subsequent message from the browser is parsed by `parseClientMessage` and dispatched to the appropriate handler on `RuntimeSessionManager`.

---

## WebSocket protocol

All messages are JSON. Client → server messages are `ClientMessage`; server → client are `ServerMessage`.

### Client message types

| Type | Purpose |
|---|---|
| `open_flow` | Subscribe to a flow and replay its current state |
| `resume_flow` | Re-attach to a running or paused flow after reconnect |
| `start_initialized_flow` | Create and start a new flow for an initialized project |
| `start_takeover_initialization` | Start an initialization flow for an existing project without `a-docs/` |
| `start_greenfield_initialization` | Start an initialization flow for a brand-new project |
| `human_input` | Send a human reply to a paused node |
| `stop_active_turn` | Abort the active LLM turn for a node or role |
| `compact_context` | Manually trigger context compaction for a role |
| `improvement_choice` | Select graph-based, parallel, or none after forward pass closes |
| `improvement_human_input` | Send human input to a paused improvement-phase role |
| `feedback_consent_choice` | Grant or deny the upstream feedback step |
| `consent_response` | Respond to a tool permission prompt (allow once, allow flow, deny) |
| `consent_mode` | Change the flow-wide consent mode |

### Server message types

| Type | When sent |
|---|---|
| `init` | On WebSocket connection — sends project list |
| `flow_summaries` | When the flow list for a project changes |
| `flow_state` | After any state change — includes full `FlowRun`, `backwardActive`, context usage |
| `feed_replay` | On `open_flow` — replays all persisted feed items so the UI can reconstruct its history |
| `operator_event` | Live events emitted during orchestration (role active, handoff, repair, consent, etc.) |
| `request_sent` / `receiving_response` / `response_end` | LLM API call lifecycle markers |
| `error` | Unrecoverable error for the current flow |

---

## SocketHub

`SocketHub` (`socket-hub.ts`) is a simple subscription registry:

- `add(socket)` / `remove(socket)` — track connected clients
- `subscribe(socket, ref)` — associate a socket with a `FlowRef` (one socket = one active flow)
- `broadcastToFlow(ref, message)` — send to all sockets subscribed to that flow
- `send(socket, message)` — send to a specific socket

All live orchestration output goes through `broadcastToFlow`. Multiple browser tabs can observe the same flow simultaneously.

---

## RuntimeSessionManager (`runtime-session/manager.ts`)

The manager owns the in-memory `activeSessions` map (`flowKey → ActiveSession`) and coordinates:

- **`createSession`** — instantiates a `FlowOrchestrator`, `ImprovementOrchestrator`, `ConsentGateImpl`, and `WebSocketOperatorSink` for a flow. Loads persisted feed history to reconstruct context usage.
- **`startFlowRunner`** — calls `orchestrator.runStoredFlow(...)` in a detached promise attached to the session's `task` field.
- **`openFlow`** — subscribes the socket and replays current state (feed history + flow state). Does not start orchestration.
- **`resumeFlow`** — subscribes the socket, re-creates the session if needed, and re-attaches the flow runner if the flow is in a runnable state.
- **`replaySessionState`** — sends `feed_replay` + `flow_state` + any in-flight consent requests to a newly-connected socket so the UI has full context on arrival.

### `ActiveSession`

The in-memory runtime object for a live flow:

```ts
{
  flowRef: FlowRef;
  sink: WebSocketOperatorSink;         // routes operator events to the socket
  orchestrator: FlowOrchestrator;      // forward pass driver
  improvementOrchestrator: ImprovementOrchestrator;
  consentGate: ConsentGateImpl;        // tool permission gate
  roleFeedHistory: Map<string, FeedItem[]>;  // in-memory feed (also persisted to feed.json)
  lastFlowState: FlowStateMessage | null;    // cached for reconnect replay
  finished: boolean;                   // true when the flow has completed
  task: Promise<void>;                 // the running orchestration promise
  latestContextUsageByRole: Record<string, number>;
  // ... compaction bookkeeping
}
```

---

## Role turn pipeline (`role-turn.ts`)

`runRoleTurn` is the core function that drives a single agent turn to completion. It:

1. Optionally runs pre-turn auto-compaction if context usage is above threshold
2. Validates that the last message in history is a `user` message (required for the LLM)
3. Calls `executeSessionTurn`, which calls `LLMGateway.executeTurn` — the actual model API call
4. Parses the assistant's response with `HandoffInterpreter.parse` to extract the `handoff` block
5. Returns a `RoleTurnResult` (`handoff` + `contextUsage`) or `null` on abort/error

`runRoleTurn` is called inside a `while(true)` loop in `FlowOrchestrator.advanceFlow`. The loop continues as long as the turn produces a repair (malformed handoff or workflow error) — each repair injects a correction message and loops. A successful handoff, a `prompt-human`, or an abort breaks the loop.

### Operator events

`WebSocketOperatorSink` bridges the orchestrator to the WebSocket. Every `OperatorEvent` emitted by the orchestrator is serialized and broadcast to all sockets subscribed to the flow. The UI uses these to update the feed in real time. Key events:

| Event | When |
|---|---|
| `role.active` | A node's role session starts |
| `role.resumed` | A node's session resumes after an interrupted turn |
| `handoff.applied` | A valid handoff was processed |
| `repair.requested` | Malformed handoff or workflow error — correction injected |
| `human.awaiting_input` | Node suspended, waiting for human reply |
| `consent.requested` | A tool call hit the consent gate |
| `consent.resolved` | Consent decision received |
| `flow.forward_pass_closed` | The terminal node emitted `forward-pass-closed` |
| `session.compacted` | Context compaction completed for a role |
| `usage.turn_summary` | Token usage after a completed turn |

---

## Human input routing

Human input from the UI arrives as a `human_input` WebSocket message. The manager's `handleHumanInput` stores the text in `flowRun.pendingHumanInputs[nodeId]` (durable — survives restarts), then wakes the orchestrator's `WakeController` so the scheduler loop picks up the pending input on its next iteration.

The orchestrator's `claimRunnableWorkForParallelRun` includes nodes from `pendingHumanInputs ∩ awaitingHumanNodes` in the runnable set. When such a node is claimed, the stored text is delivered as a user message and the `pendingHumanInputs` entry is deleted.

---

## Consent gate (`consent-gate.ts`)

`ConsentGateImpl` intercepts tool calls from `LLMGateway` before they execute. When a call requires consent, it:

1. Suspends the turn by throwing `LLMGatewayError('CONSENT_DENIED')` after storing the request
2. Emits a `consent.requested` event so the UI can show the prompt
3. Waits for `consentGate.respond(decision, role)` to be called from the UI

Decisions:
- `allow_once` — proceeds without storing
- `allow_flow` — proceeds and adds to `allowedCommands`, switches mode to `partial-access`
- `deny` — the turn ends with `awaiting_human` and `reason: 'consent-denied'`

The consent state is persisted in `flow.json` so flow-scoped approvals survive restarts.
