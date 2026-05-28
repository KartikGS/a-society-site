---
title: FAQ
description: Common questions about A-Society — model support, non-technical projects, licensing, comparisons, and existing project adoption.
---

## What models does A-Society support?

Any model accessible via the Anthropic or OpenAI API format. The runtime ships with adapters for both. For a custom provider, enter a compatible base URL in the Provider field of Settings.

Tested and recommended:

- **Anthropic:** `claude-sonnet-4-6`, `claude-opus-4-7`
- **OpenAI:** `gpt-4o`, `gpt-4o-mini`

Model IDs are entered as plain strings — no special prefixing required.

---

## Does A-Society work with non-technical projects?

Yes, after setup.

Setup requires a **technical operator** or a technical environment. You need git, Node.js, an API key, and the ability to run a local server. That's the honest answer, and it's stated clearly in the framework's vision.

But the work the harness supports doesn't have to be technical. Once `a-docs/` is initialized, the workflow and roles can serve a writing project, research project, legal project, design project, or mixed-domain project equally. The framework is domain-flexible after setup.

---

## Is A-Society free?

A-Society is **MIT-licensed** and completely free to use, modify, and distribute.

You pay your own LLM API costs. A-Society does not proxy your API calls, store your prompts, or connect to any A-Society-operated service. All computation happens locally and through your chosen provider.

---

## How is A-Society different from other agent frameworks?

Most agent frameworks focus on **agent capabilities** — tool calling, chain-of-thought, memory retrieval, multi-agent orchestration. They make the agent smarter or more capable.

A-Society focuses on the **project's operating environment**: structured memory so agents arrive oriented, role separation so different expertise applies at the right time, workflow enforcement so completeness is structural, and feedback loops so friction improves defaults.

It's not a better agent. It's a better harness for any agent.

You can use A-Society alongside an agent framework. A-Society handles orientation, workflow routing, record-keeping, and improvement. Your agent framework handles tool execution and reasoning mechanics.

---

## Can I use A-Society with my existing project?

Yes. A-Society sits alongside your project as a peer directory:

```
your-workspace/
├── a-society/        ← clone here
└── my-project/       ← your existing project
```

When you select your project in the runtime UI, A-Society runs an initialization flow that:

1. Reads your project's existing files to understand its structure, conventions, and current state
2. Asks targeted questions about anything it can't infer
3. Fills `a-docs/` surfaces with what it learned

At the end of initialization, you review and approve the `a-docs/` contents before the project is marked ready. If any surface is wrong or incomplete, you correct it before approving.

A-Society does not modify your project files. It only adds the `a-docs/` folder inside your project directory.

---

## What happens if I stop the runtime mid-flow?

Sessions are checkpointed to disk. When you restart the runtime and reopen the flow, the active node and its context are restored. In-flight LLM calls that didn't complete are replayed from the last checkpoint.

You won't lose flow state from a clean shutdown or a crash.

---

## Can I run A-Society on a remote server?

Yes, with caveats. The runtime is a local Node.js server designed for operator use. You can run it on a remote machine and access the UI over a network, but:

- There is no built-in authentication. Exposing it to the public internet without additional protection is not recommended.
- API keys are stored in the runtime's local settings file on the server — protect that file appropriately.
- For team use, each operator should run their own runtime instance against the same shared project folder.

---

## How does the feedback system work? Is my project data shared?

**No data is shared without your explicit decision for each flow.**

The backward-pass meta-analysis runs entirely locally. After it completes, the runtime asks whether to generate an A-Society feedback artifact for that specific flow. If you say No, the flow closes without any upstream artifact. If you say Yes, the runtime writes a markdown report into `a-society/feedback/` on your machine — you then review it and can submit it upstream via a GitHub PR if you choose.

The runtime never auto-submits anything. Your project data stays local unless you actively choose to share it.

---

## Is there a hosted version?

Not currently. A-Society is a local-first framework by design. A hosted variant would require significant additions to authentication, multi-tenancy, and privacy infrastructure. If there is enough demand, it's something to consider for the future.

---

## Where do I report bugs or request features?

[GitHub Issues](https://github.com/KartikGS/a-society/issues). Please include your Node version, OS, and the relevant section of the runtime log.
