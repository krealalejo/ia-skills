---
name: aws
description: >
  AWS application-side rules: credential handling, least privilege from the caller's
  side, SDK v3 usage, retries and idempotency, and per-service patterns.
  Trigger: Writing application code that talks to AWS, or handling credentials. For IaC templates, IAM policy authoring or CI pipelines use `cloud-infra`.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# AWS — application side

## When to Use

- Writing application code that calls an AWS service through the SDK.
- Handling credentials, secrets or IAM permissions from the caller's side.
- Reviewing retry, pagination or idempotency behaviour around AWS calls.
- For `template.yaml`, CloudFormation, Terraform or CI pipelines use `cloud-infra` instead.

## Critical Patterns

### Boundary with `cloud-infra`

| Concern | Skill |
|---------|-------|
| `template.yaml`, CFN, Terraform, CI, policy documents, deploy safety | `cloud-infra` |
| SDK clients, credentials at runtime, retries, service call patterns | **here** |

Both apply on a Lambda that has its own template — load both.

### Credentials — the rules that never bend

1. **Never hardcode.** No access key, secret, session token, or account id as a literal,
   a default parameter, a test fixture, or a comment. Not even a "temporary" one.
2. **Never construct a credentials object by hand.** Let the default provider chain
   resolve it. On Lambda/ECS/EC2 that is the execution role; locally it is a named
   profile via `AWS_PROFILE`.
   ```ts
   const s3 = new S3Client({}); // correct: chain resolves the role
   ```
3. **Roles, not users.** Long-lived IAM user keys are a last resort. CI authenticates
   with OIDC and assumes a role; it never stores keys.
4. **Cross-account = `sts:AssumeRole`** with an external id where applicable. Never share
   a key across accounts.
5. **Secrets come from Secrets Manager or SSM `SecureString`**, fetched at runtime by
   name, cached in the module scope for the container's life. A secret is never a build
   argument, never baked into an image, never a plaintext env var in a template.
6. **Never log a credential.** No dumping `process.env`, no logging a signed URL, no
   logging a full request object. Redact before logging, not after.
7. `.env`, `~/.aws/credentials`, `*.pem` are never read, echoed, or committed.

### Least privilege, from the caller's side

- One role per function. A shared role accumulates permissions until it is a root key.
- The code should need only the actions it performs — if you are adding a call that needs
  a new permission, say so explicitly so the policy change is reviewed.
- Read and write are separate grants. A reader that can write is a future incident.
- Scope to a concrete ARN, including the key prefix for S3 and the table/index for
  DynamoDB. `Resource: "*"` needs a written justification (see `infra`).
- Never call `iam:*`, `sts:AssumeRole` on an unbounded target, or a `*:Delete*` action
  from application code paths that handle user input.

### SDK v3

- **Modular imports.** `@aws-sdk/client-s3`, not the v2 monolith. Import only the
  commands used — bundle size is cold-start latency.
- **Instantiate clients once, at module scope**, outside the handler. A client created
  per invocation re-resolves credentials and re-opens sockets on every call.
- Always set an explicit `region`; never rely on an ambient default in a deployed artifact.
- Set timeouts below the caller's budget, and keep sockets alive:
  ```ts
  const client = new DynamoDBClient({
    requestHandler: { requestTimeout: 3_000, connectionTimeout: 1_000 },
    maxAttempts: 3,
  });
  ```
- Use `DynamoDBDocumentClient` rather than hand-writing attribute-value maps.
- **Paginate with the paginators** (`paginateScan`, `paginateListObjectsV2`). A single
  call returning a page you treat as the whole result set is the classic silent bug.
- Never use the v2 `.promise()` style or callbacks in new code.

### Retries, throttling, idempotency

- The SDK retries with backoff and jitter — configure `maxAttempts`, do not write your
  own retry loop around it.
- Distinguish retryable (`ThrottlingException`, `ProvisionedThroughputExceeded`, 5xx)
  from terminal (`ValidationException`, `AccessDenied`, 4xx). Retrying a 4xx is a bug.
- Every write that can be replayed carries an idempotency key or a condition expression.
  At-least-once delivery is the normal case, not the edge case.
- Catch the specific error class, never a bare `catch` that swallows.

### Per-service

**S3** — server-side encryption on every put; block public access; presigned URLs with the
shortest viable expiry and never logged; `ListObjectsV2` paginated; multipart for large
objects; never build a bucket policy from user input.

**DynamoDB** — design for the access pattern before writing code; `Query`, never `Scan`,
in a request path; condition expressions for optimistic concurrency; `BatchWrite` respects
the 25-item limit and **you must retry `UnprocessedItems`**; project only needed attributes.

**SQS** — long polling (`WaitTimeSeconds: 20`); visibility timeout ≥ 6× handler timeout;
DLQ configured; delete the message only after successful processing; report partial batch
failures rather than failing the batch.

**Secrets Manager / SSM** — fetch once per container and cache; handle rotation by
catching auth failure and refetching; never write a fetched secret to a log or a file.

**KMS** — encrypt with a CMK you control for anything sensitive; grant `kms:Decrypt`
separately from `kms:Encrypt`.

## Red Flags
A literal `AKIA…` · `new S3Client({ credentials: { accessKeyId: … } })` · a client built
inside a handler · a `Scan` in a request path · an unpaginated `List*` · a hand-rolled
retry loop · a bare `catch` around an SDK call · `Resource: "*"` from app code · a secret
in an env var literal · logging a presigned URL or a request object.
