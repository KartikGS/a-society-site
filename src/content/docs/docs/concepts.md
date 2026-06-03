---
title: Concepts
description: Mental models for a-docs, roles, workflows, flows, the backward pass, and why A-Society uses multiple agents instead of one.
---

This page explains the mental models behind A-Society. Understanding these will help you get the most out of the framework — and know when to follow a workflow versus when to step outside it.

---

## What is `a-docs/`?

`a-docs/` is the agent documentation layer for a project. It is a structured set of files that agents read to orient themselves to the project — without requiring the human to re-explain everything from scratch.

A complete `a-docs/` layer tells an arriving agent:

- What tools to use (no guessing, no defaulting to familiar choices)
- What the rules are (constraints, forbidden alternatives, non-negotiables)
- Who owns what (role boundaries, explicit not implied)
- Where to find things (key files registered in a discoverable index)
- How the work moves (workflows, handoffs, review gates, closure rules)
- What the project remembers (decisions, standing context, flow records)
- How to verify their work (compliance is checkable, not assumed)

**`a-docs/` is not a snapshot of a finished project.** It starts rough and improves alongside the project. A vague vision produces rough `a-docs/`; as the vision sharpens, any role that touches a surface can update it, and the documentation improves alongside the project.

### What's in a typical `a-docs/`

| Path | Contents |
|---|---|
| `agents.md` | Universal rules — constraints and conventions that apply to every agent regardless of role |
| `project-information/` | Vision, structure, architecture, and principles |
| `roles/` | Role definitions, ownership files, required readings |
| `indexes/` | File path index — single source of truth for all key paths |
| `workflow/` | Canonical workflow definition for the project |
| `communication/` | Conversation templates and coordination protocols |
| `improvement/` | Backward-pass and meta-analysis instructions |

---

## What are roles?

Roles are specialized agent perspectives. Each role brings a different type of expertise to the work. The roles in any given project are defined during initialization and tailored to that project — there is no fixed set that every project shares. Common archetypes are a coordinating role (an Owner-type), a documentation stewardship role, a design authority role, and one or more implementation roles, but the actual roles, their names, and their boundaries are project-specific.

Roles exist because **different types of expertise produce different perspectives**. An agent evaluating whether something belongs in the project is applying different judgment than the one who drafted it. A reviewer checking against acceptance criteria is thinking differently than the implementer who produced it. The combination of perspectives is what makes the output reliable.

Roles are not agents you instantiate yourself. The runtime manages which role is active and delivers that role's required context for the current node.

### The `roles/` folder

Each role in `a-docs/roles/` is a subfolder named in kebab-case after the role. Every role folder must contain exactly three files:

| File | Purpose |
|---|---|
| `main.md` | The role's identity, responsibilities, constraints, and working style |
| `ownership.yaml` | The file surfaces this role owns — paths or directories the role is responsible for keeping accurate |
| `required-readings.yaml` | The `a-docs/` variables the runtime loads into the agent's context at session start |

### System prompt injection

When the runtime starts a role session, it builds a context bundle and injects it as the system prompt. The bundle contains:

1. **Role announcement** — identifies the role and the project
2. **Runtime session contracts** — the handoff protocol and records protocol, enforced by the runtime for all roles
3. **Required readings** — every file listed in the role's `required-readings.yaml`, resolved from the index and loaded in full

Required readings are specified as index variables (e.g. `$MY_PROJECT_VISION`) rather than raw paths. The runtime resolves each variable against `a-docs/indexes/main.md` and injects the file content directly. The agent enters the session with these files already loaded — it does not need to read them on its first turn.

### Ownership validation

Each role's `ownership.yaml` declares a list of surfaces — file paths or directory prefixes the role owns. The runtime validates at health-check time that every tracked file in the project is covered by at least one role's ownership surface. Any file not claimed by a role is flagged as an error. This prevents responsibility gaps from forming silently.

### Non-overlapping required readings

The runtime also checks that node-level `required_readings` (per-node context declared in `workflow.yaml`) do not duplicate files already loaded as part of a role's startup context. If a workflow node requests a variable that the role's `required-readings.yaml` already covers, the runtime flags it as a redundant injection error. This keeps the context bundle minimal and avoids confusion from repeated injections.

---

## What are workflows?

A workflow is the **designed process** by which agents with different expertise collaborate on a unit of work. It lives in `a-docs/workflow/main.yaml` and is the canonical definition the runtime uses to route every flow.

### Workflow-level keys

<table>
<colgroup><col style="width: 14rem" /><col /></colgroup>
<thead><tr><th>Key</th><th>Description</th></tr></thead>
<tbody>
<tr><td><code>name</code></td><td>Human-readable name for the workflow</td></tr>
<tr><td><code>summary</code></td><td>What this workflow is for</td></tr>
<tr><td><code>invariants</code></td><td>Named rules that must hold across the entire flow — the runtime surfaces violations; each has a <code>name</code> and a <code>rule</code></td></tr>
<tr><td><code>escalation</code></td><td>Situations that require human judgment, with the role that escalates and who it escalates to</td></tr>
</tbody>
</table>

### Node keys

Each node in `workflow.nodes` is a role step. Every node must have `id` and `role`; the rest are optional but the runtime validates that no unknown keys are present.

<table>
<colgroup><col style="width: 14rem" /><col /></colgroup>
<thead><tr><th>Key</th><th>Description</th></tr></thead>
<tbody>
<tr><td><code>id</code></td><td>Unique kebab-case identifier for the node</td></tr>
<tr><td><code>role</code></td><td>The role that runs this node — must match a folder under <code>a-docs/roles/</code></td></tr>
<tr><td><code>human-collaborative</code></td><td>Labels a node as requiring human involvement; value is a free-form string describing the collaboration mode (e.g. <code>direction</code>, <code>approval</code>, <code>closure</code>)</td></tr>
<tr><td><code>required_readings</code></td><td>Index variables for documents loaded into the agent's context at first entry to this node — must not duplicate the role's startup readings</td></tr>
<tr><td><code>guidance</code></td><td>Behavioral directives the agent follows during this node</td></tr>
<tr><td><code>inputs</code></td><td>What the agent expects to receive when this node starts</td></tr>
<tr><td><code>work</code></td><td>The specific tasks the agent performs at this node</td></tr>
<tr><td><code>outputs</code></td><td>Artifacts or decisions the agent produces before handing off</td></tr>
<tr><td><code>transitions</code></td><td>Routing logic — conditions that determine which node comes next</td></tr>
<tr><td><code>notes</code></td><td>Non-behavioral annotations for workflow authors</td></tr>
</tbody>
</table>

**Role instances:** A role value like `owner` gives the node the `owner` base role authority and its required readings. To run the same base role at multiple nodes with separate session histories, append a numeric suffix: `owner_2`, `owner_3`, etc. Each instance gets its own isolated session — the runtime loads the base role's required readings but keeps transcripts separate. This is useful when a coordinating role appears at both intake and closure and you want those to be distinct conversations.

### Edge keys

Each edge in `workflow.edges` connects one node's output to another's input.

| Key | Description |
|---|---|
| `from` | Source node `id` |
| `to` | Destination node `id` |
| `artifact` | The artifact type passed along this edge (e.g. `handoff-brief`, `completion-report`) |

When every phase runs, completeness is **structural** — not a matter of one agent's self-assessment.

A workflow does not prevent you from working outside it. The coordinating role can choose to handle something directly. But when a flow runs through the designed workflow, you get structural verification: the right expertise applied at the right time, with handoffs and closure checks enforced.

---

## What is a flow?

A flow is a single unit of work routed through the workflow. It has:

- A **record folder** in `.a-society/state/{project}/{flow-id}/record/` with a unique timestamp ID
- A `record.yaml` with the flow ID, name, and summary
- A `workflow.yaml` representing the active forward-pass path
- Artifact files produced during the flow

The forward pass is the work-delivery phase. The backward pass is the reflection phase.

Flows are immutable once closed. You can read them for context, but you don't rewrite them to match newer conventions — they are historical traceability artifacts.

### Handoffs

Each node ends by emitting a handoff block. The runtime parses this block and routes accordingly. There are two forms:

**Target handoff** — routes work to a direct neighbor node:
```yaml
target_node_id: some-node
artifact_path: path/to/artifact.md
```
The artifact file must already exist on disk before the handoff is emitted — the runtime verifies this and rejects the handoff if the file is missing. Artifact paths must also be unique across the flow's history; an artifact used in a previous handoff cannot be reused.

A node can only hand off to its direct neighbors — immediate successors (forward) or predecessors it has already received work from (backward). Attempting to skip nodes is rejected.

**Typed signal handoffs** — special control signals:

| Signal | When to use |
|---|---|
| `forward-pass-closed` | The terminal node confirms all touched surfaces are accounted for and the forward pass is done |
| `prompt-human` | The node needs human input before it can continue — the node pauses and waits |
| `await-handoff` | The node has sent a backward correction to a predecessor and is now waiting for the revised forward handoff in return |

### Partial fan-out

A node does not have to hand off to all its successors at once. If a node has multiple outgoing edges and only satisfies some of them in a given turn, the runtime re-activates it when the remaining edges still need to be resolved. This means a node can complete work in phases — handing off to one successor now and returning later to hand off to another.

### Role serialization

Only one node per role instance runs at a time. If two runnable nodes share the same role instance, the scheduler holds the second until the first completes. This keeps each role's session history coherent.

### Backward handoff and stale artifacts

If a node finds that work from an earlier node needs correction, it can send a backward handoff to that predecessor. The runtime:

1. Re-activates the predecessor with the correction artifact
2. Marks the current node as `awaiting-handoff` — it suspends and waits for a revised forward handoff in return
3. Un-completes the predecessor's original outgoing edge so the revised work can flow forward again

While a backward correction is in flight, the original forward artifact from the predecessor is treated as **stale** — the runtime will not deliver it to the current node until the backward handoff has been resolved and a fresh forward handoff arrives. This prevents the node from acting on superseded work.

### Node suspension states

A node can be suspended for several reasons:

| State | Cause |
|---|---|
| Awaiting human input | Agent emitted `prompt-human`, or the runtime stopped it for another reason (consent denied, interrupted turn, autonomous abort) |
| Awaiting handoff | Agent emitted `await-handoff` after sending a backward correction — waiting for the predecessor's revised response |

---

## What is the backward pass?

After the forward pass closes, the runtime offers three choices — **graph-based**, **parallel**, or **none**. Both meta-analysis and feedback are optional. Your choice applies only to the current flow.

### Meta-analysis phase

Every role that participated in the forward pass — including the Owner — runs a findings session. Each role reflects on what happened during their forward-pass work using the meta-analysis instructions in `a-docs/improvement/meta-analysis.md`. The reflection is grounded in specific moments from execution: conflicting instructions, missing information, unclear guidance, scope ambiguities, workflow friction, and role file gaps.

Each role writes its findings to a deterministic path: `{record-folder}/findings/{role-instance-id}-findings.md`. The path is assigned by the runtime — roles cannot choose a different location.

Meta-analysis sessions continue from the role's existing forward-pass session, so the agent can reflect on the actual tool calls, decisions, and errors it made — not a reconstructed summary. This is why findings tend to be specific rather than generic.

**Direct corrections:** During meta-analysis, each role can directly update the standing surfaces it owns when the correction is clear and unambiguous. These are local a-docs fixes — not deferred, not escalated, just corrected in place. Historical record artifacts are immutable and cannot be rewritten.

### Graph-based vs parallel mode

**Graph-based** — the runtime computes the backward-pass order from the flow's `workflow.yaml`. Roles run in reverse order of their first appearance in the forward pass: roles that ran later go first, earlier roles go later. As each role completes its findings session, those findings are injected into its direct predecessors in the forward-pass role graph when they run. Each role sees the findings from its immediate downstream neighbors — not the full set of all findings.

**Parallel** — all non-Owner roles run their findings sessions concurrently, with no cross-injection between peers. After all of them complete, the Owner runs with all non-Owner findings injected.

Graph-based is appropriate when the forward-pass had meaningful dependencies between roles and you want each role's reflection to be informed by what its downstream counterpart observed. Parallel is faster and appropriate when the roles worked independently.

### Feedback phase

After all meta-analysis sessions complete, the runtime pauses and asks separately whether to run a feedback pass. This is a second, independent consent gate.

The feedback phase runs a dedicated role in a **fresh session** — not any of the project roles, and not the Owner. This session is given a runtime-provided system prompt (not the project's a-docs context) and receives all findings files from the just-completed meta-analysis as its source material.

The feedback session's purpose is entirely different from meta-analysis. It is not about local a-docs maintenance — that belongs in meta-analysis. It is about what the A-Society framework itself should change: additions to `general/`, runtime or tooling improvements, cross-project patterns or anti-patterns, framework-level documentation gaps. Each candidate improvement in the artifact is classified as **Universal** (applies to all project types), **Category-shaped** (applies to a recognizable class of projects), or **Project-specific** (only relevant to this project).

The artifact is written locally to `a-society/feedback/{project}-flow-{flow-id}.md` for your review. You read it, decide what's worth sharing, redact anything sensitive, and optionally open a pull request to the A-Society repository. The runtime does not submit anything automatically — the file includes a suggested PR title and body to make submission low-friction when you choose to share.

