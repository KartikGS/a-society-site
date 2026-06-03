---
title: Flow State
description: The FlowRun object — what it contains, how each field is populated, and how the runtime uses it.
---

> These pages describe the current implementation. They may lag behind code changes.

The runtime's source of truth for an active flow is a single JSON object — `FlowRun` — persisted at:

```
.a-society/state/{projectNamespace}/{flowId}/flow.json
```

`SessionStore.saveFlowRun` writes it; `SessionStore.loadFlowRun` reads and validates it. All mutations go through `SessionStore.updateFlowRun`, which serializes concurrent writes using a per-flow async lock so no two coroutines corrupt each other's state.

`recordName` and `recordSummary` are stripped before writing to disk — they are re-derived from `workflow.yaml` at load time via `syncRecordMetadataFromWorkflow`.

---

## Identity fields

| Field | Type | Description |
|---|---|---|
| `flowId` | `string` | Unique timestamp-based ID (e.g. `20260527T143000123Z-a1b2c3`). Set at flow creation, never changes. |
| `projectNamespace` | `string` | The project subfolder name (e.g. `my-project`). Together with `flowId` forms the `FlowRef` used everywhere. |
| `workspaceRoot` | `string` | Absolute path to the workspace root. Verified on load — a mismatch throws rather than silently proceeding. |
| `recordFolderPath` | `string` | Absolute path to the flow's record folder inside the project. Contains `workflow.yaml`, `record.yaml`, and all artifacts. |
| `stateVersion` | `string` | Schema version string. Current value is `CURRENT_FLOW_STATE_VERSION` in `types.ts`. Load fails if this doesn't match — flows cannot be reopened after a breaking schema change. |

---

## Execution state

### `status`

```
'running' | 'awaiting_improvement_choice' | 'awaiting_feedback_consent' | 'completed'
```

Controls what the scheduler does next:
- `running` — the scheduler picks up runnable nodes
- `awaiting_improvement_choice` — forward pass closed; waiting for the human to choose graph-based, parallel, or none
- `awaiting_feedback_consent` — meta-analysis complete; waiting for human decision on feedback
- `completed` — flow is done; no further orchestration

### `runningNodes`

`string[]` — node IDs claimed by an active role turn. A node enters this list when the scheduler claims it (`claimRunnableWorkForParallelRun`) and leaves when the turn completes or the node is suspended.

Only one node per role instance can be in `runningNodes` at a time — the scheduler enforces this to prevent the same role's session from being used concurrently.

### `awaitingHumanNodes`

`Record<string, { role: string; reason: AwaitingHumanReason }>` — nodes paused waiting for human input. The reason field is one of:

| Reason | Cause |
|---|---|
| `prompt-human` | Agent emitted a `prompt-human` signal |
| `autonomous-abort` | Turn returned `null` without a handoff |
| `consent` | A consent prompt is in-flight (transitional — rarely persisted) |
| `consent-denied` | A tool call was denied and the turn was stopped |

### `pendingHumanInputs`

`Record<string, { text: string; receivedAt: string }>` — human replies queued by the UI before the scheduler has consumed them. Keyed by node ID. When the scheduler picks up a node from this map it delivers the text as a user message and removes the entry.

### `visitedNodeIds`

`string[]` — node IDs whose first-entry workflow guidance has already been delivered. The runtime injects the node contract (guidance, inputs, work, outputs, etc.) only on first entry. If the node is re-entered (e.g. after a backward handoff), the contract is not re-injected.

---

## Handoff tracking

### `completedHandoffs`

`string[]` — edge keys (`"${from}=>${to}"`) for forward handoffs that have been realized. An entry here means the source node successfully handed off to the target. A backward handoff removes the entry so the edge can be traversed again with corrected work.

### `receivingHandoff`

`Record<string, string[]>` — maps edge keys to artifact paths queued along that edge. Both forward and backward handoffs populate this. The orchestrator reads this when building the node-entry message so the receiving node gets the artifact in context.

### `historyHandoff`

`Record<string, string[]>` — the full cumulative history of artifacts ever sent along each edge, deduplicated. Used solely to reject artifact reuse — an agent cannot pass the same artifact path twice across the flow's lifetime.

### `awaitingHandoff`

`string[]` — node IDs currently suspended after emitting a backward handoff. They are waiting for the predecessor to send a revised forward handoff back. A node in this list is not runnable and not in `runningNodes`.

---

## Consent state

### `consentState`

```ts
{
  mode: 'no-access' | 'partial-access' | 'full-access';
  bash: {
    allowedCommands: Record<string, { command: string; grantedAt: string }>;
  };
}
```

Persisted with the flow so consent grants survive server restarts. `allowedCommands` is keyed by exact command string. On load, `normalizeConsentState` sanitizes it — unrecognized modes fall back to `no-access`.

---

## Improvement phase

### `improvementPhase`

Present only after the forward pass closes. See type `ImprovementPhaseState`:

| Field | Description |
|---|---|
| `status` | `awaiting_choice` → `running` → `awaiting_feedback_consent` → `completed` (or `skipped`) |
| `mode` | `graph-based`, `parallel`, or `none` — set when the human makes the improvement choice |
| `completedRoles` | Role instance IDs whose meta-analysis session has finished |
| `runningRoles` | Role instance IDs with a session in progress |
| `awaitingHumanRoles` | Roles blocked on human input during improvement |
| `pendingHumanInputs` | Queued human replies for improvement roles |
| `findingsProduced` | Maps role instance ID → findings file path (repo-relative) |
| `improvementWorkflowPath` | Repo-relative path to the runtime-generated `improvement.yaml` |
| `feedbackArtifactPath` | Runtime-assigned path for the upstream feedback artifact |
| `feedbackConsent` | `pending`, `granted`, or `denied` |
| `singleRole` | `true` when the workflow has only one unique base role — affects UI presentation |

### `feedbackContext`

`{ kind: 'standard' | 'initialization'; initializationMode?: 'takeover' | 'greenfield' }` — tells the feedback session whether this was a normal flow or an initialization flow, which changes the focus instructions injected into the feedback session.
