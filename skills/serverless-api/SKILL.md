---
name: serverless-api
description: >
  Backend API rules for serverless TypeScript handlers: contract design, validation,
  error mapping, idempotency, queue and event consumers, logging and auth.
  Trigger: Writing or reviewing HTTP handlers, endpoints, queue/event consumers or service-to-service contracts. Not for UI, SQL schema or IaC.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# API / Lambda services (TypeScript)

## When to Use

Editing a handler, an endpoint, a queue/event consumer, or a cross-service contract.

## Critical Patterns

### Handler shape

Keep the Lambda entry point thin — three layers, always:

```
handler.ts    parse + validate input, map result to HTTP/queue response, catch → error map
service.ts    business logic. Pure-ish. No AWS SDK, no event shapes. Unit-tested directly.
repository.ts data access. The only place that knows about SQL or DynamoDB.
```

A handler that calls the SDK directly is untestable. Do not write one.

### Contracts

- Define request/response types in `packages/*-contracts` and import them. Never redeclare.
- **Additive changes only.** New fields optional with a default. To remove or retype a field:
  expand → migrate consumers → contract, across separate releases.
- Version in the path (`/v1/…`) only when a break is genuinely unavoidable.
- A service never reads another service's database. Endpoint or event — no third option.

### Validation & errors

- Validate at the edge with zod. Past the boundary, trust the type.
- Never return a raw exception, a stack trace, or a DB error to a caller.
- One error mapper per service. Stable machine-readable codes:

  | Status | When |
  |--------|------|
  | 400 | schema/validation failure — include which field |
  | 401 / 403 | unauthenticated / authenticated but not allowed |
  | 404 | absent, or present but not visible to this caller |
  | 409 | conflict, version mismatch, duplicate |
  | 422 | well-formed but semantically rejected |
  | 429 | throttled — set `Retry-After` |
  | 5xx | your fault. Log with correlation id; return an opaque message. |

### Async consumers (SQS / EventBridge)

- **Every consumer is idempotent.** Dedupe on a message/business key; redelivery is normal,
  not exceptional.
- SQS batches: use partial batch failure (`batchItemFailures`). Never fail a whole batch
  for one bad message.
- Configure a DLQ. A queue without one silently loses data.
- Poison messages go to the DLQ, they do not retry forever.
- Events are facts in the past tense (`DeviceRegistered`), carry a schema version, and
  never carry a secret or a PII blob the consumer does not need.

### Auth

- Verify the token at the edge (authorizer). Handlers receive an already-trusted principal.
- Authorize on every request, per resource. Never infer permission from the UI's behaviour.
- Fail closed: unknown role, missing claim, or unparseable token → deny.
- Never log a token, a full auth header, or PII.

### Observability

Structured JSON logs only. Every log line carries a correlation id propagated from the
inbound request through every downstream call and queue message. No `console.log` in a
handler. Log the decision and the outcome, never the payload wholesale.

### Lambda specifics

Initialize clients and connection pools **outside** the handler. Keep the bundle small
(heavy deps → a layer). Set an explicit timeout below the caller's. Assume a cold start
and an at-least-once invocation — both will happen.

## Red Flags
SDK calls inside a handler · an unvalidated body · a `catch` that swallows · a consumer
with no dedupe · a cross-service DB read · a secret in an env var literal · an endpoint
with no test for its 4xx path.
