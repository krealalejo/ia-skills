---
name: postgres
description: >
  PostgreSQL rules: schema design, indexing, query performance, transactions and
  forward-only migration safety (expand/migrate/contract).
  Trigger: Writing SQL, changing a schema, adding an index, writing a migration or diagnosing a slow query. A schema change always needs a plan first.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# PostgreSQL / Aurora

## When to Use

Writing SQL, touching a schema or migration, adding an index, or investigating query
performance. **A schema change always crosses the Plan Mode threshold — plan first.**

## Critical Patterns

### Schema

- `snake_case` everywhere. Tables plural (`products`), columns singular.
- Every table: a surrogate PK (`uuid` default `gen_random_uuid()`, or `bigint identity`),
  plus `created_at timestamptz not null default now()` and `updated_at timestamptz`.
- **`timestamptz`, never `timestamp`.** Store UTC. Convert at the edge.
- `numeric` for money. Never `float`/`double` — silent rounding loss.
- `text` over `varchar(n)` unless the limit is a real business rule.
- Declare constraints in the database: `not null`, `check`, `unique`, and every FK.
  Application-level validation is a convenience, not the guarantee.
- Nullable means "genuinely unknown". Do not use `null` as a flag or an empty string.
- JSONB for genuinely open-ended data only. If you query a key often, promote it to a
  column. JSONB is not a way to avoid designing the schema.

### Indexes

- Index every FK — Postgres does not do it for you, and it will bite on delete and join.
- Composite index column order = equality columns first, then range, then sort.
- Partial index for a selective predicate: `where deleted_at is null`.
- `EXPLAIN (ANALYZE, BUFFERS)` **before** adding an index and after. No guessing.
- On a live table: `CREATE INDEX CONCURRENTLY` (and it cannot run inside a transaction).
- Unused indexes cost every write. Check `pg_stat_user_indexes` before adding another.

### Queries

- Always parameterized. String-interpolated SQL is an injection bug — no exceptions,
  including for "internal" or "admin-only" paths.
- Never `SELECT *` in application code; the column list is part of your contract.
- Keyset pagination (`where (created_at, id) < (…)`) over `OFFSET` on large tables.
- `EXISTS` over `COUNT(*) > 0`. `JOIN` over a query inside a loop.
- Set a `statement_timeout`. An unbounded query will eventually take the database with it.

### Transactions

Keep them short — no network calls, no user input, no S3 upload inside one. Acquire locks
in a consistent order across the codebase to avoid deadlocks. Default isolation is Read
Committed; if you need `SERIALIZABLE`, you must also handle the retry. Never hold a
transaction open across a Lambda's await of an external service.

### Migrations — forward-only, expand/migrate/contract

Sequential, immutable, reviewed. Never edit a migration that has been applied anywhere.

A destructive change is **three separate releases**:

1. **Expand** — add the new nullable column/table/index. Deploy. Nothing reads it yet.
2. **Migrate** — backfill in batches; write to both old and new. Deploy. Switch reads.
3. **Contract** — once nothing references the old shape, drop it. Deploy.

Never in one release: add `not null` without a default on a populated table · rename a
column · drop a column still referenced · change a type in place · add a FK without
`NOT VALID` then `VALIDATE CONSTRAINT`.

Backfill in bounded batches with a sleep. A single `UPDATE` over millions of rows locks
the table and blocks production.

### Aurora / PostGIS notes

- Route read-only work to the reader endpoint; expect replica lag — never read-after-write
  from a replica.
- Lambda + Postgres: use RDS Proxy or a pooler. Unpooled Lambda connections exhaust
  `max_connections` under load.
- PostGIS: pick the SRID deliberately (4326 lat/lon vs a projected metric CRS), always
  index geometry with GiST, and use `ST_DWithin` (index-usable) rather than `ST_Distance < x`.

## Red Flags
Interpolated SQL · an unindexed FK · `timestamp` without zone · `float` money · a
migration that drops and recreates · `OFFSET 50000` · a transaction wrapping an HTTP call ·
`SELECT *` shipped to production.
