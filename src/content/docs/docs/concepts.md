---
title: Concepts
description: Mental models for a-docs, roles, workflows, flows, the backward pass, and why A-Society uses multiple agents instead of one.
---

This page explains the mental models behind A-Society. Understanding these will help you get the most out of the framework — and know when to follow a workflow versus when to step outside it.

---

## What is `a-docs/`?

`a-docs/` is the agent documentation layer for a project. It is a structured set of files that agents read at the start of a session to orient themselves to the project — without requiring the human to re-explain everything from scratch.

A complete `a-docs/` layer tells an arriving agent:

- What tools to use (no guessing, no defaulting to familiar choices)
- What the rules are (constraints, forbidden alternatives, non-negotiables)
- Who owns what (role boundaries, explicit not implied)
- Where to find things (key files registered in a discoverable index)
- How the work moves (workflows, handoffs, review gates, closure rules)
- What the project remembers (decisions, standing context, flow records)
- How to verify their work (compliance is checkable, not assumed)

**`a-docs/` is not a snapshot of a finished project.** It starts rough and improves alongside the project. A vague vision produces rough `a-docs/`; as the vision sharpens, the Curator brings the documentation in line.

### What's in a typical `a-docs/`

| Path | Contents |
|---|---|
| `agents.md` | Entry point — the first file any agent reads |
| `project-information/` | Vision, structure, architecture, and principles |
| `roles/` | Role definitions, ownership files, required readings |
| `indexes/` | File path index — single source of truth for all key paths |
| `workflow/` | Canonical workflow definition for the project |
| `records/` | Convention file and all completed flow record folders |
| `communication/` | Conversation templates and coordination protocols |
| `improvement/` | Backward-pass and meta-analysis instructions |

---

## What are roles?

Roles are specialized agent perspectives. Each role brings a different type of expertise to the work.

**The Owner** coordinates the project — routes work, sets requirements, validates outcomes, and protects the vision. The Owner does not design domain-internal solutions.

**The Curator** stewards documentation surfaces — `general/` content, indexes, guides, communication templates, and improvement protocols. The Curator designs solutions within the documentation domain.

**The Technical Architect** (for projects with an executable layer) designs executable boundaries, role splits, and implementation structure. The TA does not implement — it designs and reviews.

**Developer roles** (Framework Services Developer, Orchestration Developer, UI Developer) implement within defined executable domains, under the TA's design authority.

Roles exist because **different types of expertise produce different perspectives**. An Owner evaluating whether an addition belongs is applying different judgment than a Curator who drafted it. A reviewer checking against acceptance criteria is thinking differently than the implementer who produced it. The combination of perspectives is what makes the output reliable.

Roles are not agents you instantiate yourself. The runtime manages which role is active and delivers that role's required context for the current node.

---

## What are workflows?

A workflow is the **designed process** by which agents with different expertise collaborate on a unit of work.

Each workflow is a directed graph of nodes and edges:
- Each **node** is a role step: it has a role, inputs it expects, work it does, and outputs it produces.
- Each **edge** connects one node's output to the next node's input, with an artifact type (handoff brief, proposal, decision, completion report).
- **Invariants** define rules that must hold across the entire flow (e.g., no path can close while a touched surface is stale).

When every phase runs, completeness is **structural** — not a matter of one agent's self-assessment.

A workflow does not prevent you from working outside it. The Owner can choose to handle something directly. But when a flow runs through the designed workflow, you get structural verification: the right expertise applied at the right time, with handoffs and closure checks enforced.

---

## What is a flow?

A flow is a single unit of work routed through the workflow. It has:

- A **record folder** in `a-docs/records/` with a unique timestamp ID
- A `record.yaml` with the flow ID, name, and summary
- A `workflow.yaml` representing the active forward-pass path
- **Sequenced artifacts**: `01-owner-workflow-plan.md`, `02-owner-to-curator.md`, etc.

The forward pass is the work-delivery phase. The backward pass is the reflection phase.

Flows are immutable once closed. You can read them for context, but you don't rewrite them to match newer conventions — they are historical traceability artifacts.

---

## What is the backward pass?

After a flow's forward work is done and the Owner confirms closure, the backward pass begins.

Each participating role (except the Owner, who closes the forward pass) runs a **findings session** — a focused reflection on:
- What went well
- What caused friction
- What patterns from this flow could generalize to other projects
- What improvements to suggest for the framework

Findings are saved as sequenced artifacts in the record folder. A **Synthesis** session (run by a fresh agent, not the Owner) then reads all findings and produces a consolidated backward-pass synthesis artifact.

**Backward-pass meta-analysis** runs locally and does not send anything upstream. After it completes, the runtime asks whether to generate an A-Society feedback artifact — that step is entirely optional and requires explicit consent.

The value of the backward pass accumulates over time. Patterns found in multiple flows become candidates for `general/` templates. Friction found in multiple projects becomes a Next Priority for the framework.

---

## Why multiple roles instead of one agent?

A single agent can do many things. But a single agent doing everything produces work that is **complete by its own assessment** — not by structural verification. It plans, implements, and reviews its own work without friction. The work feels done. It may not be done.

Roles exist because the combination of expert perspectives makes the output reliable.

Consider a Curator drafting a new instruction document. The Curator knows documentation structure, but may expand scope in ways that drift from the framework vision. The Owner review catches this — not because the Owner is smarter, but because the Owner is asking a different question: *"Does this belong here?"* That question is not being asked during drafting.

This is not theoretical overhead. It is the mechanism by which the framework guarantees quality without relying on any individual agent's self-judgment.

**Human-directed work is not exempt.** When you identify a need and direct the work, that direction enters the workflow — it does not bypass it. The Owner receives the direction, routes it into the appropriate workflow, and the designed role separation ensures completeness. Bypassing the workflow means losing the perspectives the workflow was designed to include.

The framework puts it plainly: *A poorly harnessed project makes a great agent guess. The investment is in the operating system around the work — not only in the agent itself.*
