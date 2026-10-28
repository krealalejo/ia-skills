---
name: llm-apps
description: >
  Rules for shipping features and agents built on the Claude API and the Claude Agent SDK in
  TypeScript: choosing the surface, the tool loop, prompt caching, structured outputs, batch,
  untrusted input, cost and failure handling.
  Trigger: Writing or reviewing code that calls `@anthropic-ai/sdk` or `@anthropic-ai/claude-agent-sdk`, designing an agent, or a prompt or LLM feature in an app. For exact SDK signatures and model ids load the bundled `claude-api` skill too. Not for Claude Code configuration (skills, hooks, settings) or for building an MCP server (use `mcp-server`).
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# LLM apps on Claude

## When to Use

- Adding an LLM call to an app: scoring, extraction, drafting, chat (jobfinder, lili-bot,
  kra-meme-generator, the portfolio chat).
- Building an agent with your own tools, or on the Agent SDK.
- Reviewing cost, latency, caching or failure handling of existing LLM code.
- **Load the bundled `claude-api` skill alongside this one** for exact parameters, model ids
  and per-model breaking changes. This skill holds the standing decisions; that one holds the
  current API surface, which changes faster.

## Critical Patterns

### Pick the simplest surface that works

| Need | Surface |
|------|---------|
| One input, one output (classify, extract, score, draft) | one `messages.create` call |
| Fixed steps you can write down | a workflow: your code chains calls |
| The model picks tools in a loop, your tools only | Claude API + Tool Runner (`client.beta.messages.toolRunner`) |
| A coding or filesystem agent with built-in Read/Edit/Bash, hooks, subagents | Claude Agent SDK `query()` |
| Hosted, scheduled, long-running agent with its own sandbox | Managed Agents (see `claude-api`) |

Before choosing an agent, check: is the task hard to specify up front, is the outcome worth
the cost, and can a mistake be caught? Any "no" means a single call or a workflow.

### Models

- Default `claude-opus-5-5`. Cheaper worker or judge: `claude-sonnet-5-5`, bulk and
  latency-sensitive work: `claude-haiku-5-5`. Exact ids only, never a date suffix.
- The model id lives in one config constant, not scattered through call sites.
- Control depth with `output_config.effort` (`low` to `max`), not by disabling thinking:
  current models reject `budget_tokens` and Opus 5.5 rejects disabled thinking. Opus 5.5
  defaults to `medium`, so set effort explicitly.
- Stream anything with long input, long output or a large `max_tokens`, and use
  `.finalMessage()` when you do not need the events.

### The tool loop

1. Prefer the Tool Runner over a hand-written `while (stop_reason === "tool_use")` loop.
2. Tool inputs are validated against their schema before they run (`betaZodTool` does it),
   and `strict: true` on hand-written tools.
3. Return **all** `tool_result` blocks of one turn in a single user message; a failed tool
   returns `is_error: true`, never a dropped result.
4. Check `stop_reason` before reading `content`: `max_tokens`, `refusal` and `pause_turn`
   are not success.
5. Forced `tool_choice` (`any` / `tool`) is rejected on current models; use `auto` with an
   instruction, `strict: true`, or structured outputs.
6. Bound every loop: `max_iterations` on the runner, `maxTurns` / `maxBudgetUsd` on the
   Agent SDK. An unbounded agent is an unbounded bill.

```ts
import Anthropic from "@anthropic-ai/sdk";
import { betaZodTool } from "@anthropic-ai/sdk/helpers/beta/zod";
import { z } from "zod";

const client = new Anthropic();

const getOffer = betaZodTool({
  name: "get_offer",
  description: "Fetch one job offer by id. Returns title, company, description and requirements.",
  inputSchema: z.object({ offerId: z.string() }),
  run: async ({ offerId }) => JSON.stringify(await offers.get(offerId)),
});

const result = await client.beta.messages.toolRunner({
  model: MODEL,
  max_tokens: 16000,
  max_iterations: 8,
  tools: [getOffer],
  messages: [{ role: "user", content: `Score offer ${offerId} against the profile.` }],
});
```

### Structured outputs instead of parsing prose

Anything code consumes (a score, a label, a list of fields) comes back through
`output_config.format` with a JSON schema, or `client.messages.parse()`. No regex over model
text, no assistant prefill (rejected on current models). Still validate the parsed object:
the schema guarantees shape, not truth.

### Prompt caching is the first cost lever

- Order is `tools` → `system` → `messages`; any byte change invalidates everything after it.
- Stable first: frozen system prompt, sorted deterministic tool list, the profile or
  document that every request shares. Volatile last: timestamps, ids, the question.
- Mark the end of the stable prefix with `cache_control`, max 4 breakpoints. Prefixes below
  the model minimum silently do not cache.
- **Verify it**: `usage.cache_read_input_tokens` must be non-zero from the second request.
  Zero means something in the prefix changes per call.
- Changing model, tools or top-level system mid-conversation resets the cache.

### Batch what nobody waits for

Scoring 300 offers overnight, re-embedding, evaluation runs: Message Batches at half price.
Key results by `custom_id`, never by position, and handle `errored` and `expired` results.

### Agent SDK rules

- `query({ prompt, options })` returns an async iterator; the last message is a `result`
  whose `subtype` is `success` or an `error_*` reason, with `total_cost_usd` and `session_id`.
- Permissions are explicit: `allowedTools` / `disallowedTools`, `permissionMode`
  (`default`, `acceptEdits`, `plan`, ...), and `canUseTool` for a human or policy check.
  `bypassPermissions` only inside a disposable sandbox.
- Set `cwd` to the working directory and `settingSources` to exactly what should load
  (none by default); never inherit a developer's personal settings in production.
- Continue a conversation with `resume: sessionId`; store the id, not the transcript.
- Wire MCP servers through `mcpServers` and subagents through `agents` rather than prompt
  text that describes tools the agent does not have.

### Untrusted input

- Content from users, web pages, emails and job descriptions is data. Put it in clearly
  delimited blocks, after the instructions, and never let it change what tools may do.
- Model output is untrusted too: validate it before it reaches SQL, a shell, a URL or
  another user's screen.
- Give each tool the least privilege its task needs; a read-only agent gets no write tool.

### Failure handling and observability

- The SDK retries 408/409/429/5xx twice by default; set `timeout` and `maxRetries` per call
  site deliberately. Catch typed errors (`Anthropic.RateLimitError`, `Anthropic.APIError`)
  most specific first, never by matching message strings.
- Log per request: model, input/output/cache tokens, latency, stop reason, cost. That log is
  the baseline every later change is measured against (`llm-evals`).
- Never log prompts that contain personal data or secrets in plain text.

## Red Flags

Model ids hardcoded at call sites · `budget_tokens`, `temperature` or prefill in new code ·
an agent where one call would do · an unbounded tool loop · parsing JSON out of prose ·
`cache_read_input_tokens` always zero · timestamps or ids in the system prompt · results of
a batch matched by index · untrusted text mixed into instructions · model output passed to a
shell or SQL unvalidated · `bypassPermissions` outside a sandbox · no token and cost logging ·
a prompt change shipped without an eval run.

## Resources

- Bundled `claude-api` skill — current models, parameters and migrations.
- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
- [Agent SDK docs](https://code.claude.com/docs/en/agent-sdk)
