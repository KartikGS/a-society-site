---
title: Runtime Guide
description: Operator-facing reference for the A-Society runtime — starting the server, the browser UI, project lifecycle, and flow management.
---

The A-Society runtime is a local Node.js server with a browser UI. This guide covers everything you need to operate it day-to-day.

> **Canonical source:** `runtime/INVOCATION.md` in the A-Society repository is the authoritative operator reference. This guide presents the same information in a more narrative form.

---

## Starting the runtime

```bash
npm --prefix ./a-society/runtime install   # first time only
npm --prefix ./a-society/runtime start
```

The runtime starts at **[http://localhost:3000](http://localhost:3000)** by default.

**Environment variables:**

| Variable | Default | Description |
|---|---|---|
| `PORT` | `3000` | HTTP port for the local server |
| `WORKSPACE_ROOT` | parent of `a-society/` | Root directory scanned for projects |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | — | OpenTelemetry OTLP endpoint (optional) |

Set variables before starting:

```bash
PORT=4000 npm --prefix ./a-society/runtime start
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
- Sequenced artifact files (`01-owner-workflow-plan.md`, `02-owner-to-curator.md`, etc.)

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
- **Role handoff** — when the Owner routes work to a downstream role, the UI shows the handoff artifact and prompts you to start the next session

### Session continuity

Sessions survive server restarts. If you close the browser or restart the runtime, reopening the flow at `localhost:3000` restores the active node and its context. Partially completed role turns are recoverable from the saved session state.

### Tool permissions

Each flow can run in one of three permission modes:

| Mode | Behavior |
|---|---|
| **Interactive** | Prompts for permission on each tool call |
| **Auto-approve safe** | Auto-approves read-only and reversible tools; prompts for destructive ones |
| **Full auto** | Approves all tool calls without prompting |

Set the permission mode from the flow settings panel before starting a role session.

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

After the forward pass closes, the runtime offers:

1. **Backward-pass meta-analysis** — each participating role runs a findings session reflecting on what worked, what caused friction, and what patterns could generalize. Runs locally; no upstream sharing.

2. **Upstream feedback** (optional) — after backward pass completes, the runtime asks whether to generate an A-Society feedback artifact for the just-closed flow. This requires your explicit decision. If you say Yes, the runtime writes one markdown report to `a-society/feedback/`. If you say No, the flow closes without any upstream artifact.

Consent for one flow does not imply consent for future flows.

---

## OpenTelemetry observability

The runtime exports traces and metrics via OpenTelemetry. Set `OTEL_EXPORTER_OTLP_ENDPOINT` to your OTLP collector endpoint to enable:

- Per-session trace spans
- Tool call counts and latencies
- Prompt and completion token metrics per model call
- Backward-pass phase timing

Without a configured endpoint, telemetry is collected but not exported.

---

## Stopping the runtime

`Ctrl+C` in the terminal window. Active sessions are checkpointed to disk before shutdown; in-flight LLM calls complete if the shutdown timeout allows.
