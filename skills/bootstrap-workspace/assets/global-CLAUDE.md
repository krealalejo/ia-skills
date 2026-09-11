# Global Operating Rules

Scope: applies to every repository. A repo-level `CLAUDE.md` may add rules or tighten
these, never loosen them. On conflict: **repo rules win, except the HARD RULES below,
which are never overridable — not even by an explicit user request in-session.**

Deep context lives in `~/.claude/AGENTS.md` (architecture) and `~/.claude/skills/*`
(domain detail, loaded on demand). Do not inline that content here.

---

## 0. Output rules (always apply)

- **Answer in English.** Every reply, plan, commit message, PRD and summary is written
  in English, regardless of the language the user writes in. The only exception is an
  explicit in-session request to use another language, and it lasts only as long as the
  user says so.
- **No comments in code.** Do not add comments to code you write or edit — no
  explanatory comments, no section banners, no TODO/FIXME notes, no JSDoc/docblocks
  added for their own sake. Existing comments stay as they are unless the change makes
  them wrong, and comments the user explicitly asks for are of course written.
  Explain the code in the reply, not in the file.

---

## 1. Stack baseline

- **Language:** TypeScript (strict). PHP/Symfony and Ruby appear in isolated services only.
- **Frontend:** Vue 3 / Nuxt, Angular, React — all Vite-built. Vuetify or Tailwind.
- **Backend:** AWS Lambda (SAM), API Gateway, SQS, EventBridge, DynamoDB.
- **Data:** Aurora PostgreSQL (+ PostGIS), DynamoDB for event/aggregate state.
- **Monorepo:** npm workspaces + Nx. Node 24 / npm 10.
- **Test:** Vitest (unit), Playwright (e2e). **Lint:** ESLint. **Hooks:** husky / lefthook.

Never assume a stack. Read `package.json` / `nx.json` / `template.yaml` before choosing tools.

---

## 2. HARD RULES (non-negotiable)

**Git**
1. Never commit on `main` / `master`. If HEAD is on one, stop and ask for a branch name.
2. Never push to `main` / `master` — no `git push origin main`, no push with main upstream,
   no force-push to a protected branch.
3. Never create Pull Requests (`gh pr create`, PR API, PR URLs). The human opens PRs.
4. Never use `--no-verify`, `--force` (use `--force-with-lease` if truly needed), or any
   flag whose purpose is to bypass a hook or a check.
5. Never rewrite published history (`rebase`/`amend`/`reset --hard` on a pushed branch).

**Execution**
6. Never run repo-wide `npm run build` / `npm run test` / `npm run lint`. They fan out
   across every workspace and cost minutes. Scope it: `npx nx run <project>:<target>`.
7. Never run a command whose blast radius you have not read: `rm -rf`, `chmod -R 777`,
   `curl … | sh`, `docker system prune`, `DROP`/`TRUNCATE`, `terraform destroy`.
8. Never touch production. No deploys, no migrations against a live DB, no `sam deploy`,
   no writes to prod buckets/tables — unless the user names the environment in that message.

**Secrets**
9. Never read, echo, commit, or paste the contents of `.env*`, `*.pem`, `id_*`,
   `~/.aws/credentials`, or any token. Reference variables by name only.
10. Never write credentials into `CLAUDE.md`, `AGENTS.md`, a PRD, or a commit message.

**Permission**
11. Before any outward-facing or hard-to-reverse action (push, deploy, delete, external
    API write, posting anywhere), state what you are about to do and get explicit approval.
    Approval for one action is not approval for the next one.

---

## 3. Plan Mode gate

Produce a written plan and **wait for approval** before editing, whenever the change:

- touches **3 or more files**, or
- adds/removes/upgrades a **dependency**, or
- alters a **data model** (SQL schema, DynamoDB keys, API contract, shared type), or
- changes **infrastructure** (`template.yaml`, IAM, CI), or
- is a **migration, refactor, or rename** crossing a workspace boundary.

The plan states: goal · files to touch · order of operations · risk · rollback ·
how it will be verified. Below the threshold, just do the work.

---

## 4. Context protocol — 60% rule

At **60% of the context window**, stop taking on new work and run **Document & Clear**:

1. Write `docs/sessions/<YYYY-MM-DD>-<slug>.md` with: Mission (from the PRD), Done,
   In progress (exact file + line), Next steps, Decisions made, Gotchas, Open questions.
2. Tell the user the file is written and that you are clearing.
3. `/clear`.
4. Resume by reading the PRD, then that session file, then only the files it names.

Never let the window auto-compact mid-task — a summary loses the decisions, the file
notes do not. Between steps: prefer subagents for wide searches so their output stays
out of the main window.

---

## 5. PRD-first

Every non-trivial task starts from a PRD at `docs/prd/<slug>.md`, copied from
`~/.claude/templates/PRD.md`. If none exists, write one and get it approved first.

**You may not invent scope.** Anything not listed under *In Scope* — extra endpoints,
a password-reset flow, caching, retries, a new dependency, "while I was in there"
refactors — is out. If you believe something is genuinely required, say so and wait.
Silence in the PRD means "not now", not "use your judgement".

---

## 6. Workflow preferences

- **Atomic commits.** One logical change each; must build and pass tests on its own.
  Conventional Commits: `type(scope): subject`, imperative, ≤300 chars total.
- Run the repo formatter (`format:fix` or equivalent) on touched projects after editing.
- Match surrounding code: its naming and its idioms. No new patterns without a reason
  stated in the plan. Comments are governed by section 0 — do not add any.
- Tests belong in the same commit as the behaviour they cover.
- Report honestly: if tests fail, show the output; if you skipped a step, say so.
  Never claim verification you did not perform.
- Ask when two readings of a request would produce materially different work.
  Otherwise decide, state the assumption, and continue.

---

## 7. Domain knowledge is on-demand

`~/.claude/skills/` holds the detailed rules, one directory per domain:
`react/` · `vue/` · `javascript/` · `css/` · `serverless-api/` · `php/` · `postgres/` · `aws/` · `cloud-infra/`

Load a skill **only** when the work actually enters that domain — do not preload them.
A skill may point to companion files in its own directory; read those on demand too.
Add new domains as directories there, never as sections in this file.
