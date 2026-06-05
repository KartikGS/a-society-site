---
title: Model Configuration
description: How to configure providers, models, context windows, and reasoning for the A-Society runtime.
---

Model configuration is managed through the Settings panel in the browser UI (gear icon, any view). Settings are persisted locally to `.a-society/settings.json`; API keys are stored separately in `.a-society/secrets.json`. Both files are written with mode `0600`.

On first launch, the Settings panel opens automatically and blocks navigation until at least one model is configured and activated.

---

## Model fields

Each configured model has the following fields:

<table>
<colgroup><col style="width: 14rem"></colgroup>
<thead><tr><th>Field</th><th>Description</th></tr></thead>
<tbody>
<tr><td><code>displayName</code></td><td>A label shown in the UI. Does not affect API calls.</td></tr>
<tr><td><code>providerType</code></td><td><code>anthropic</code> or <code>openai-compatible</code>.</td></tr>
<tr><td><code>providerBaseUrl</code></td><td>Required for <code>openai-compatible</code>. The base URL of the API endpoint (e.g. <code>https://api.openai.com/v1</code>).</td></tr>
<tr><td><code>modelId</code></td><td>The model identifier passed to the API (e.g. <code>claude-opus-4-5</code>, <code>gpt-4o</code>).</td></tr>
<tr><td><code>contextWindow</code></td><td>The model's context window in tokens. Used to calculate the auto-compaction threshold (80% of this value). Set it to match your model's actual context window.</td></tr>
<tr><td><code>maxOutputTokens</code></td><td>Maximum tokens per response. Defaults: 4096 for Anthropic, 8192 for OpenAI-compatible. For manual Anthropic thinking, the thinking budget must be less than this value.</td></tr>
<tr><td><code>reasoning</code></td><td>Reasoning configuration. See below.</td></tr>
<tr><td><code>supportedInputTypes</code></td><td>Optional. Declare which input modalities the model supports: <code>image</code>, <code>audio</code>, <code>video</code>. Stored with the model config but not yet acted on by the runtime.</td></tr>
</tbody>
</table>

---

## Active model

Only one model can be active at a time. The active model is used for all role turns and for compaction LLM calls. The first model you add is automatically activated. You can switch the active model at any time from the Settings panel — the change takes effect on the next turn.

---

## Reasoning configuration

Reasoning is configured per model. The mode must be compatible with the provider:

- `anthropic` provider: `disabled`, `anthropic-adaptive`, `anthropic-manual`
- `openai-compatible` provider: `disabled`, `openai-chat`, `custom-openai-compatible`

### `disabled`

No reasoning. The model responds with standard output only.

### `openai-chat`

OpenAI reasoning models (e.g. `o3`, `o4-mini`). Sends `reasoning_effort` and uses `max_completion_tokens` instead of `max_tokens`.

<table>
<colgroup><col style="width: 10rem"><col style="width: 16rem"></colgroup>
<thead><tr><th>Field</th><th>Values</th><th>Description</th></tr></thead>
<tbody>
<tr><td><code>effort</code></td><td><code>none</code>, <code>minimal</code>, <code>low</code>, <code>medium</code>, <code>high</code>, <code>xhigh</code></td><td>Controls how much reasoning the model performs.</td></tr>
</tbody>
</table>

### `anthropic-adaptive`

Anthropic extended thinking in adaptive mode. The model decides how much thinking to use based on the task. Sends `thinking.type: "adaptive"` and `output_config.effort`.

<table>
<colgroup><col style="width: 10rem"><col style="width: 16rem"></colgroup>
<thead><tr><th>Field</th><th>Values</th><th>Description</th></tr></thead>
<tbody>
<tr><td><code>effort</code></td><td><code>low</code>, <code>medium</code>, <code>high</code>, <code>xhigh</code>, <code>max</code></td><td>Guides the model's thinking depth.</td></tr>
<tr><td><code>display</code></td><td><code>omitted</code>, <code>summarized</code></td><td>Whether thinking content is omitted or summarized in the feed.</td></tr>
</tbody>
</table>

### `anthropic-manual`

Anthropic extended thinking with an explicit token budget. You control exactly how many tokens are allocated for thinking. Sends `thinking.type: "enabled"` with `budget_tokens`.

<table>
<colgroup><col style="width: 10rem"><col style="width: 16rem"></colgroup>
<thead><tr><th>Field</th><th>Values</th><th>Description</th></tr></thead>
<tbody>
<tr><td><code>effort</code></td><td><code>low</code>, <code>medium</code>, <code>high</code>, <code>xhigh</code>, <code>max</code></td><td>Guides the model's thinking depth.</td></tr>
<tr><td><code>display</code></td><td><code>omitted</code>, <code>summarized</code></td><td>Whether thinking content is omitted or summarized in the feed.</td></tr>
<tr><td><code>budgetTokens</code></td><td>positive integer</td><td>Thinking token budget. Must be less than <code>maxOutputTokens</code>.</td></tr>
</tbody>
</table>

### `custom-openai-compatible`

For providers that expose reasoning through non-standard API fields (e.g. DeepSeek, local models). Lets you inject arbitrary request body fields and optionally configure how the reasoning trace is rendered in the UI.

**Request configuration** (`request`):

<table>
<colgroup><col style="width: 10rem"><col style="width: 16rem"></colgroup>
<thead><tr><th>Field</th><th>Values</th><th>Description</th></tr></thead>
<tbody>
<tr><td><code>tokenLimitParam</code></td><td><code>max_tokens</code>, <code>max_completion_tokens</code></td><td>Which request field to use for the output token limit.</td></tr>
<tr><td><code>extraBody</code></td><td><code>Record&lt;string, unknown&gt;</code></td><td>Additional fields merged into the API request body. Cannot override reserved keys: <code>model</code>, <code>messages</code>, <code>stream</code>, <code>stream_options</code>, <code>tools</code>, <code>max_tokens</code>, <code>max_completion_tokens</code>.</td></tr>
</tbody>
</table>

**Trace configuration** (`trace`, optional):

If the provider streams a reasoning trace in the response, you can configure how it is captured and displayed.

<table>
<colgroup><col style="width: 10rem"><col style="width: 16rem"></colgroup>
<thead><tr><th>Field</th><th>Values</th><th>Description</th></tr></thead>
<tbody>
<tr><td><code>responseDeltaField</code></td><td>string</td><td>The field name in each streaming delta that carries the reasoning content.</td></tr>
<tr><td><code>requestMessageField</code></td><td>string</td><td>The field name used to replay reasoning content back to the model in subsequent messages.</td></tr>
<tr><td><code>replay</code></td><td><code>never</code>, <code>tool-calls-only</code>, <code>always</code></td><td>When to replay reasoning traces back to the model. <code>tool-calls-only</code> is the default — replays only on turns that involved tool calls.</td></tr>
<tr><td><code>display</code></td><td><code>hidden</code>, <code>collapsed</code>, <code>expanded</code></td><td>How reasoning traces appear in the UI feed.</td></tr>
<tr><td><code>label</code></td><td>string</td><td>Display label for the reasoning trace in the feed (e.g. <code>"Thinking"</code>).</td></tr>
</tbody>
</table>

Both `responseDeltaField` and `requestMessageField` must be set for the trace configuration to take effect.

---

## Compaction model

Context compaction uses the same active model via a separate `LLMGateway` instance in `system` mode — no tools, no consent gate. The same reasoning configuration, `maxOutputTokens`, and API key apply. Compaction runs as a standard text turn and its token usage is not tracked against the role session.
