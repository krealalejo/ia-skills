---
name: mcp-server
description: >
  Rules for building Model Context Protocol servers in TypeScript: tool design, input and
  output schemas, transports, auth, errors, testing and registering the server with Claude Code.
  Trigger: Writing or reviewing an MCP server, adding a tool to one, or exposing an API to agents ("make an MCP for X"). Not for configuring someone else's server in Claude Code (use `claude mcp add` directly), or for the Claude API tool loop (use `llm-apps`).
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# MCP servers

## When to Use

- Building a new MCP server (`jobfinder-mcp`, `kra-mcp`) or adding a tool to one.
- Reviewing an MCP server before other people or agents depend on it.
- Turning an existing REST API or CLI into something an agent can call.
- For the Claude API's own tool-use loop, use `llm-apps`. For the HTTP API behind the
  server, also load `serverless-api`.

## Critical Patterns

### Pick the primitive

| Primitive | Who decides to use it | Use for |
|-----------|----------------------|---------|
| **Tool** | the model | actions and queries with arguments: `score_offer`, `create_post` |
| **Resource** | the client or user | read-only content addressed by URI: `offers://today`, a file, a schema |
| **Prompt** | the user, as a slash command | a reusable, parameterised instruction template |

Most servers need tools only. Do not wrap a static document as a tool; make it a resource.

### Tool design is API design for a model

1. **Few tools, each a whole task.** `draft_recruiter_message(offer_id)` beats three
   tools the model must chain. Every tool's name and description sits in context on every
   turn, so twenty thin tools cost tokens and confuse selection.
2. **Names are `verb_noun`, snake_case, unique across servers the user might load.**
   Prefix with the domain when collisions are likely (`kra_create_post`).
3. **The description is the prompt.** Say what it does, when to use it, when not to, and
   what it returns. Mention the cheaper tool when one exists.
4. **Typed, narrow inputs.** Zod schemas with enums, ranges and `.describe()` on every
   field. No free-form `query: string` when the model should pick from five statuses.
5. **Return what the model needs next, not the raw API response.** Trim fields, keep ids
   the next call needs, cap list sizes and say when results were truncated.
6. **Annotate side effects.** `readOnlyHint`, `destructiveHint`, `idempotentHint`,
   `openWorldHint` let clients decide what needs human approval.
7. **Destructive tools take an explicit confirmation field or a dry-run mode.** A model
   retrying on a timeout must not delete twice: make writes idempotent with a client key.

```ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({ name: "jobfinder", version: "1.0.0" });

server.registerTool(
  "set_offer_status",
  {
    title: "Set offer status",
    description: "Move one job offer to a new pipeline status. Use after the user decides on an offer. Returns the updated offer.",
    inputSchema: {
      offerId: z.string().describe("Offer id as returned by list_offers"),
      status: z.enum(["new", "shortlisted", "applied", "rejected"]).describe("Target status"),
    },
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true },
  },
  async ({ offerId, status }) => {
    const offer = await offers.setStatus(offerId, status);
    if (!offer) {
      return { isError: true, content: [{ type: "text", text: `No offer ${offerId}. Call list_offers to get valid ids.` }] };
    }
    return { content: [{ type: "text", text: JSON.stringify(offer) }] };
  },
);

await server.connect(new StdioServerTransport());
```

### Errors the model can act on

- A failed call returns `isError: true` with a message that says **what to do next**
  ("No offer abc. Call list_offers to get valid ids."), not a stack trace.
- Throw only for protocol-level failures. A business error is a result, not an exception.
- Validation lives in the schema; never trust that the model respected the description.

### Transports

| Transport | When | Rules |
|-----------|------|-------|
| **stdio** | local server, one user, launched by the client | stdout is the protocol: log to **stderr** only, never `console.log` |
| **Streamable HTTP** | remote or shared server | one endpoint, auth on every request, validate `Origin`, bind to `127.0.0.1` when local |

The old HTTP+SSE transport is deprecated; do not start new servers on it.

### Auth and secrets

- **stdio:** credentials come from env vars the user sets in the client config, read by
  name. Never from a tool argument, never written to logs or tool results.
- **HTTP:** OAuth 2.1 per the MCP authorization spec, or a bearer token validated on
  every request (for `kra-mcp`, the existing Cognito JWT). Check audience and expiry.
- **Never pass the client's token through to an upstream API.** The server holds its own
  credentials for upstream calls and maps the caller to permissions itself.
- Scope each tool to the caller: a `list_leads` tool filters by the authenticated owner on
  the server, not by an argument the model fills in.

### Treat tool output as untrusted input to the model

Anything a tool returns that came from the outside world (a job description, an email, a
web page) can carry instructions. Return it as clearly delimited data, and never let a tool
take an action because returned content asked for it.

### Testing

- Unit-test the handlers as plain functions with Vitest; the MCP layer stays thin.
- One integration test per tool through the SDK client over an in-memory or stdio
  transport: list tools, call it, assert on the result shape.
- Before shipping, drive it by hand in the MCP Inspector and in a real Claude Code session.

## Commands

```bash
npm install @modelcontextprotocol/sdk zod
npx @modelcontextprotocol/inspector node dist/index.js

claude mcp add jobfinder --scope user -e JOBFINDER_DB=/path/to/jobs.db -- node /path/to/dist/index.js
claude mcp add --transport http kra https://api.example.com/mcp --header "Authorization: Bearer $KRA_TOKEN"
claude mcp list
claude mcp get jobfinder
```

`--scope local` (default) is this project for you only, `project` writes a shared
`.mcp.json` to commit, `user` is every project on the machine.

## Red Flags

`console.log` in a stdio server · one tool per REST endpoint · free-form string inputs
where an enum fits · raw upstream JSON returned unfiltered · secrets accepted as tool
arguments or echoed in results · token passthrough to an upstream API · a destructive tool
with no annotation, confirmation or idempotency key · stack traces as error text · tool
descriptions that do not say when not to use the tool · new servers on the HTTP+SSE
transport · tools trusting a user id the model supplied.

## Resources

- [Model Context Protocol](https://modelcontextprotocol.io) — spec, SDKs, Inspector.
- [TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
