---
title: Getting Started
description: How to install A-Society, start the runtime, configure a model, and run your first flow.
---

A-Society is a standalone repository that sits alongside your project. This guide walks you from zero to your first initialized project flow.

**Requirements:** Node.js ≥ 18, npm, git.

---

## Step 1 — Set up your workspace

Clone A-Society into a workspace directory. Any projects you want to use with it live alongside it in the same parent folder — not inside it.

```
your-workspace/
├── a-society/        ← the framework (clone here)
└── my-project/       ← your project (or create one from the UI)
```

```bash
git clone https://github.com/KartikGS/a-society.git
```

A-Society never modifies files in your project directory. It adds an `a-docs/` folder inside your project during initialization, and that's the only change it makes to your project's structure.

---

## Step 2 — Install and start the runtime

```bash
npm --prefix ./a-society/runtime install
npm --prefix ./a-society/runtime start
```

The runtime opens at **[http://localhost:3000](http://localhost:3000)**.

The first time you start, the Settings panel opens automatically and stays open until you configure and activate a model. Subsequent starts go directly to the project selector.

---

## Step 3 — Configure a model

Fill in the Settings panel:

| Field | What to enter |
|---|---|
| **Provider** | `anthropic`, `openai`, or a compatible base URL |
| **API key** | From your provider's dashboard |
| **Model ID** | From your provider's model catalog |

**Anthropic:** Get your API key from the [Anthropic Console](https://console.anthropic.com).

**OpenAI:** Get your API key from the [OpenAI Platform](https://platform.openai.com).

**Compatible APIs:** Any provider offering an OpenAI-compatible base URL works. Enter the base URL in the Provider field.

Click **Save** then **Set as Active**. The settings panel closes and you're taken to the project selector.

---

## Step 4 — Select or create a project

The project selector shows three categories:

**Initialized projects** — projects with a complete `a-docs/` layer. Click any of these to see its existing records and open a new one.

**Uninitialized projects** — project folders found in your workspace that lack `a-docs/`. Click one to run the scaffold and initialization flow.

**Create New Project** — enter a project name. The runtime creates a folder in your workspace, scaffolds the compulsory `a-docs/` surfaces, and immediately opens the Owner initialization flow.

### What initialization does

The initialization flow runs an Owner agent session that:

1. Reads your project (or asks targeted questions for a new project)
2. Fills the scaffolded `a-docs/` surfaces: `agents.md`, roles, indexes, workflow, and project-information documents
3. Asks you to review and approve each surface before the project is considered ready

This typically takes one focused session. Once complete, the project is initialized and all future flows work through the designed workflow.

---

## Step 5 — Start your first flow

From the initialized project view, click **New Record**. The runtime opens a draft flow and routes it to the Owner node. The Owner reads the active context (your `a-docs/`, the workflow contract, and any relevant handoff artifacts) and asks what you want to work on.

---

## What happens at the end of a flow

When the forward pass closes, the runtime optionally runs a backward-pass meta-analysis: each participating role reflects on what went well, what caused friction, and what could improve. The runtime offers two modes — **graph-based** (roles reflect in reverse order of participation, following the flow structure) or **parallel** (all participating roles reflect concurrently). Afterward, the runtime optionally asks whether to generate upstream feedback for A-Society.

---

## Next steps

- [Runtime Guide](/docs/runtime-guide) — full reference for the browser UI and operator-facing behavior
- [Concepts](/docs/concepts) — mental models for `a-docs/`, roles, workflows, flows, and the backward pass
- [FAQ](/docs/faq) — common questions
