---
name: cloud-infra
description: >
  Infrastructure-as-code rules: IAM least privilege, environment isolation, deploy
  safety, secrets, networking, cost and observability.
  Trigger: Editing template.yaml, CloudFormation, Terraform, IAM policies or CI pipelines. Every infra change needs an approved plan first.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# Infrastructure (AWS SAM / CloudFormation / Terraform / CI)

## When to Use

Editing `template.yaml`, a CFN/Terraform file, an IAM policy, or a CI pipeline.
**Every infra change crosses the Plan Mode threshold — plan and get approval first.**

## Critical Patterns

### Non-negotiables

1. **No console changes.** If it is not in a template, it does not exist. Drift is an
   incident, not a convenience.
2. **Never deploy without being told.** No `sam deploy`, `cdk deploy`, `terraform apply`
   unless the user names the environment in that message. `terraform destroy` is never
   yours to run.
3. **Plan before apply, always.** `terraform plan` / `sam deploy --no-execute-changeset`,
   then show the diff and wait. Read the changeset for replacements before proceeding.
4. **Never commit state or secrets.** `terraform.tfstate`, `.env`, `samconfig` with real
   values, `*.pem` — all excluded, all of them.

### IAM — least privilege

- Scope every statement to a concrete resource ARN. `Resource: "*"` requires a written
  justification in the PR, and is only ever acceptable for actions that genuinely have no
  resource-level permissions.
- No `*:*`. No `iam:PassRole` without a `Condition` on the target role.
- One role per function. Never a shared "lambda-role" that accumulates permissions.
- Prefer SAM connectors / managed policies scoped to the resource over hand-rolled stars.
- Grant read separately from write. A reader that can write is a future incident.

### Environments

- Isolated accounts (or at minimum isolated stacks) per environment. Never a shared
  resource across `dev` and `prod`.
- Environment is a **parameter**, never a hardcoded arn, bucket name, or account id.
- Name resources `${AWS::StackName}-<logical>` so two environments can coexist.
- Production requires a manual approval gate in the pipeline. No exceptions.

### Secrets & config

Secrets Manager or SSM Parameter Store (`SecureString`), referenced by name and resolved
at runtime. Never a plaintext secret in a template, a CI variable a PR can echo, or a
build artifact. Rotation is configured when the secret is created, not later.

### Resource safety

- `DeletionPolicy: Retain` on every stateful resource: databases, buckets with data,
  tables. A stack rollback must not delete data.
- Buckets: block public access, encrypt (SSE-KMS), versioning on, lifecycle rules set.
- Databases: private subnets only, no public accessibility, security group scoped to the
  caller's SG (not a CIDR), backups and PITR enabled.
- Queues: **always** a DLQ with a sane `maxReceiveCount`, plus a visibility timeout of at
  least 6× the consumer's timeout.

### Networking

Lambdas go in a VPC only when they need a VPC resource — otherwise you pay ENI cold starts
for nothing. Private subnets for compute, public only for load balancers. Use VPC
endpoints for S3/DynamoDB rather than routing through a NAT gateway.

### Observability & cost

Every alarm has an action; an alarm nobody is paged for is decoration. Minimum set:
Lambda errors + throttles, DLQ depth > 0, queue age, 5xx rate, DB connections and CPU.
Log retention is **always** set explicitly — the default is "forever" and it is expensive.
Tag every resource (`Environment`, `Service`, `Owner`, `CostCenter`). Before merging,
state what the change costs per month if it is non-trivial.

### CI/CD

Least-privilege OIDC role, never long-lived access keys in CI. The pipeline runs lint →
test → build → plan → (gate) → deploy. A failing test never reaches deploy. Artifacts are
immutable and identical across environments — build once, promote the same artifact.

## Red Flags
`Resource: "*"` · a hardcoded account id or arn · a public bucket · a queue with no DLQ ·
no `DeletionPolicy` on a database · unset log retention · a plaintext secret · `0.0.0.0/0`
on anything but a load balancer · an apply with no reviewed plan.
