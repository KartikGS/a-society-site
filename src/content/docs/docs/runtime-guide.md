---
title: Runtime Guide
description: Operator-facing reference for the A-Society runtime — starting the server, the browser UI, project lifecycle, and flow management.
---

The A-Society runtime is a local Node.js server with a browser UI. This guide covers everything you need to operate it day-to-day.

## Starting the runtime

```bash
npm --prefix ./a-society/runtime install   # first time only
npm --prefix ./a-society/runtime start
```

The runtime starts at **[http://localhost:3000](http://localhost:3000)** by default.

**Environment variables:**

| Variable | Default | Description |
|---|---|---|
| `A_SOCIETY_UI_PORT` | `3000` | HTTP port for the local server |
| `A_SOCIETY_TELEMETRY_ENABLED` | `true` | Set to `false` to disable telemetry bootstrapping |
| `A_SOCIETY_OTLP_ENDPOINT` | — | OTLP/HTTP collector endpoint |
| `A_SOCIETY_OTLP_HEADERS` | — | Comma-separated `key=value` headers for the OTLP exporter |
| `A_SOCIETY_OTLP_METRICS_INTERVAL` | `60000` | Metrics export interval in milliseconds |
| `A_SOCIETY_TELEMETRY_PAYLOAD_CAPTURE` | `false` | Capture prompt/turn payload snippets in span events (may include sensitive data) |
| `A_SOCIETY_ENVIRONMENT` | — | Sets the `deployment.environment` resource attribute |

Variables can be set inline or in a `runtime/.env` file (copy `runtime/.env.sample` to get started):

```bash
A_SOCIETY_UI_PORT=4000 npm --prefix ./a-society/runtime start
```

---

## Browser UI layout

The UI has two primary modes: **Project Selector** and **Flow View**.

### Project Selector

The entry point when no flow is active. Shows:

- **Initialized projects** — projects with a complete `a-docs/` layer, ready for new flows
- **Uninitialized projects** — project folders in your workspace without `a-docs/`, ready to initialize
- **Create New Project** — creates a folder and starts the initialization flow

### Settings panel

Accessible from the gear icon in any view. Manages:

- **Provider** — `anthropic`, `openai`, or a custom base URL
- **API Key** — stored locally; never sent anywhere except your provider
- **Model ID** — any model your provider supports
- **Active model** — the model used for new sessions

On first launch, the Settings panel opens automatically and blocks navigation until a model is configured and activated.

---

## Flow lifecycle

A **flow** is a single unit of work routed through the workflow. Each flow has:

- A **record folder** with a unique timestamp ID (e.g., `20260527T143000123Z-a1b2c3`)
- A `record.yaml` with the flow ID, name, and summary
- A `workflow.yaml` tracking the active forward-pass path
- Artifact files produced during the flow

### Opening a flow

Click **New Record** from an initialized project. The runtime creates the record folder, seeds `record.yaml`, and opens the Owner node.

### Flow View

When a flow is active, the UI switches to Flow View:

- **Owner Chat** — available at Owner nodes; you collaborate with the Owner agent to plan intake, write briefs, and close the flow
- **Graph View** — React Flow visualization showing the full workflow graph with color-coded node states:
  - ⚪ Pending — not yet reached
  - 🔵 Active — current node
  - 🟢 Complete — successfully closed
  - 🟡 Needs attention — waiting for a decision or approval
- **Role handoff** — when a node emits a valid handoff, the runtime automatically loads the next node and starts the appropriate role session

### Session continuity

Sessions survive server restarts. If you close the browser or restart the runtime, reopening the UI and selecting the flow restores the active node and its context. Partially completed role turns are recoverable from the saved session state. Use the **Resume** button to continue a flow that was waiting on human input or was interrupted mid-turn.

### Tool permissions

The runtime uses a consent gate that intercepts sensitive tool calls before they execute. There are three modes:

| Mode | File writes | Bash commands |
|---|---|---|
| **No access** (default) | Require approval | Require approval (except safe read-only commands) |
| **Partial access** | Always allowed | Allowed if previously approved in this flow |
| **Full access** | Always allowed | Always allowed |

The mode can be changed at any point during a flow from the UI. It persists for the duration of the flow run.

**Approval decisions:**

- **Allow once** — approves the specific operation and resumes the session; does not persist
- **Allow flow** — approves the operation, remembers it for the rest of the flow, and switches the mode to partial access
- **Deny** — blocks the operation and pauses the node for your guidance

**Auto-allowed without prompting:**

A small set of bash commands are always permitted regardless of mode: `pwd` (no arguments) and `ls` with safe relative paths (no `..`, no absolute paths, no shell control characters). Everything else requires explicit approval in no-access mode.

**Flow-scoped bash memory:**

Bash approvals granted with Allow flow are remembered for the rest of the flow by exact command string. Any role running the same command later in the same flow proceeds without re-prompting. Approvals do not carry over to new flows.

**On resume:**

Consent prompts that were pending when the runtime shut down are treated as denied on restart. The node remains paused and waits for your input before continuing.

---

## Owner chat mode

Owner chat is the primary mode for planning, intake, and closure. The Owner agent:

- Reads the active required context for the flow
- Asks what you want to work on (at intake)
- Routes to the appropriate workflow path
- Authors the workflow plan and handoff artifacts
- Closes the forward pass when all touched surfaces are accounted for

You interact with the Owner through a standard chat interface. The Owner may ask clarifying questions, propose alternatives, or push back on scope. This is expected — the Owner's job is to protect framework coherence.

---

## Backward pass and improvement protocol

When the forward pass closes, the runtime pauses and offers three options — **graph-based**, **parallel**, or **none**. Both meta-analysis and feedback are optional, and your choice applies only to the current flow.

After meta-analysis completes, the runtime asks separately whether to run a feedback pass. This is a second, independent consent gate. If you approve, a feedback artifact is written locally to `a-society/feedback/{project}-{flow-id}.md` for your review. The runtime does not submit anything automatically.

See [Concepts — What is the backward pass?](/docs/concepts#what-is-the-backward-pass) for a detailed explanation of how meta-analysis sessions work, what findings files contain, how graph-based and parallel modes differ, and what the feedback phase produces.

---

## OpenTelemetry observability

The runtime exports traces, metrics, and logs via OpenTelemetry following the [GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/). A pre-configured local observability stack is included at `runtime/observability/` — Tempo for traces, Prometheus for metrics, Loki for logs, and Grafana for visualization.

**Starting the local stack:**

Docker is required. From your workspace:

```bash
docker compose -f ./a-society/runtime/observability/docker-compose.yaml up -d
```

Grafana opens at **[http://localhost:13000](http://localhost:13000)**. The OTLP collector listens at `http://localhost:14318`.

Set `A_SOCIETY_OTLP_ENDPOINT` to point the runtime at the collector:

```bash
A_SOCIETY_OTLP_ENDPOINT=http://localhost:14318 npm --prefix ./a-society/runtime start
```

Or add it to `runtime/.env`.

**Traces:**
- Per-turn spans (`llm.gateway.execute_turn`) wrapping the full tool loop for each role turn
- Per-API-call spans for each model request, with input and output token counts as span attributes (GenAI semantic conventions)
- Backward-pass spans (`improvement.orchestrate`) covering the full improvement phase

**Metrics:**
- `a_society.flow.started` / `a_society.flow.completed` — flow lifecycle counters
- `a_society.session.turn.started` — turn counter per role session
- `a_society.session.turn.duration` — turn duration histogram
- `a_society.handoff.parse_failure` — counter for malformed handoff blocks
- `gen_ai.client.operation.duration` — model API call duration histogram (per provider)

**Logs:**

Structured logs are exported to the same endpoint via the OTLP logs signal and available in Grafana via Loki.

---

## Stopping the runtime

Press `Ctrl+C` in the terminal window.

If there are active role sessions running, the first `Ctrl+C` aborts them gracefully — in-flight LLM calls are cancelled and each running node is checkpointed to disk as an awaiting-human node. The server stays alive. You can reconnect, select the flow, and resume from where it stopped.

If no sessions are active, or after the first `Ctrl+C` has cleared them, a second `Ctrl+C` exits the process.
