---
title: Role Sessions
description: How role sessions are stored — the RoleSession object, transcript history, feed items, and compaction archives.
---

> These pages describe the current implementation. They may lag behind code changes.

Each role instance in a flow gets its own persisted session. Sessions are stored under the flow's state directory:

```
{stateRoot}/{projectNamespace}/{flowId}/roles/{roleInstanceId}/
  transcript.json   ← RoleSession object (system prompt + full conversation history)
  feed.json         ← FeedItem array (operator-facing UI feed)
```

The state root is `{workspaceRoot}/.a-society/state`.

`SessionStore.saveRoleSession` serializes to `transcript.json`. `SessionStore.loadRoleSession` reads it back. The role key is the `instanceRoleId` (e.g. `owner`, `curator`, `owner_2`).

---

## The `RoleSession` object

```ts
interface RoleSession {
  roleName: string;
  logicalSessionId: string;
  transcriptHistory: RuntimeMessageParam[];
  currentNodeContext?: { nodeId: string; exchanges: RuntimeMessageParam[] };
  compactionArchives?: CompactionArchive[];
  isActive: boolean;
  currentNodeId?: string;
  systemPrompt?: string;
  latestContextUsage?: number;
}
```

### `roleName`

The role instance ID (e.g. `owner`, `curator_2`). Used to derive the storage key.

### `logicalSessionId`

`"{flowId}__{roleInstanceId}"` — a stable identifier scoped to the flow and role. Used as a label in telemetry and logs.

### `transcriptHistory`

The complete conversation history for this role across all nodes it has visited. Stored as `RuntimeMessageParam[]`:

```ts
type RuntimeMessageParam =
  | { role: 'user';                content: string }
  | { role: 'assistant';           content: string }
  | { role: 'assistant_tool_calls'; calls: ToolCall[]; text?: string }
  | { role: 'tool_result';         callId: string; toolName: string; content: string; isError: boolean };
```

Roles reuse their session as they move from node to node — the history accumulates. This is intentional: when a role reaches meta-analysis, it can reflect on the actual tool calls and decisions it made during the forward pass, not a reconstructed summary.

### `currentNodeContext`

Tracks the messages exchanged at the current node, separate from the full `transcriptHistory`. Used as the input to compaction — the current node's exchanges are fed into an LLM turn that produces a summary. That summary, combined with programmatic flow context, replaces the entire `transcriptHistory` as a single message. Prior nodes' history is not summarized — it is discarded (archived in `compactionArchives` for debugging only).

Structure: `{ nodeId: string; exchanges: RuntimeMessageParam[] }`.

### `systemPrompt`

The context bundle injected as the system prompt. Built once by `ContextInjectionService.buildContextBundle` and stored to avoid re-building on node re-entry or resume. Contains:
- Role announcement and record folder path
- Runtime session contracts (handoff and records protocols)
- All required readings from the role's `required-readings.yaml`, resolved from the index

### `isActive`

`true` while a turn is in progress. Set to `false` when the turn completes or the node is suspended. The runtime checks this to detect sessions that were mid-turn when the server was killed.

### `latestContextUsage`

The context window token count from the most recent completed turn. Used by the auto-compaction check to decide whether to compact before the next turn.

### `compactionArchives`

Array of compaction records. Each entry is:

```ts
{
  id: string;              // UUID
  trigger: 'manual' | 'auto';
  nodeId: string;          // node that was active when compaction ran
  compactedAt: string;     // ISO timestamp
  archivedTranscriptHistory: RuntimeMessageParam[];  // the history that was replaced
  replacementMessage: RuntimeMessageParam;           // the summary message that replaced it
}
```

When compaction runs, the full `transcriptHistory` (including the current node's exchanges) is archived here, and the entire history is replaced with a single summary message. The original history is retained in the archive for debugging.

---

## The operator feed (`feed.json`)

`feed.json` stores `FeedItem[]` — the items shown in the UI's role feed panel. This is separate from `transcript.json`. It is a projected, UI-facing view of what happened, not the raw conversation.

```ts
interface FeedItem {
  id: string;
  type: FeedItemType;
  label: string;
  text: string;
}
```

`FeedItemType` values include `assistant`, `user`, `event`, `error`, `handoff`, `resume`, `repair`, `tool`, `tool-success`, `tool-error`, and `activation`.

The feed is built from `OperatorEvent` emissions as the orchestrator runs. On reconnect, `SessionStore.loadAllRoleFeeds` reads all `feed.json` files and the server sends a `feed_replay` message to restore the UI state.

---

## Session lifecycle

1. **First node entry** — if no session exists, a new `RoleSession` is created with empty `transcriptHistory`. The context bundle is built and stored in `systemPrompt`. The node-entry user message (containing the workflow contract and any required readings) is appended.

2. **Node re-entry** (same role, later node) — the existing session is loaded. The new node-entry message is appended to the existing history, continuing the same conversation.

3. **Interrupt and resume** — if a turn was in-flight when the server stopped, `isActive` will be `true` on load and the last message in history will be an `assistant` message. The runtime appends an `INTERRUPTED_TURN_CONTINUATION_MESSAGE` prompt to recover.

4. **Meta-analysis** — the improvement orchestrator continues from the role's existing forward-pass session so the agent can reflect on what it actually did. Only the feedback role (`a-society-feedback`) gets a completely fresh session.
