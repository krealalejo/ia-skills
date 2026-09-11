# AGENTS.md — <Repo Name>

> Repo-level architecture reference. Extends `~/.claude/AGENTS.md`; that file is the
> fallback for anything not stated here. Safety and git rules live in `CLAUDE.md`.

## What this repo is

<Two or three sentences. What it does, who uses it, what it is not.>

## Repository map

| Path | What it is | Stack |
|------|-----------|-------|
| `<path>` | <purpose> | <stack> |

## Key flows

<The one or two cross-cutting flows a newcomer must understand, as a chain:
`A → B → queue → C → D`. Link the design docs.>

## Design decisions specific to this repo

| # | Decision | Why | Consequence |
|---|----------|-----|-------------|
| 1 | | | |

## Boundaries

- <What must never import what.>
- <What owns which data.>
- <Which directories are generated / must not be hand-edited.>

## Local commands

| Task | Command |
|------|---------|
| Build one project | `npx nx run <project>:build` |
| Test one project | `npx nx run <project>:test` |
| Format touched code | `npx nx run <project>:format:fix` |

> Never the repo-wide `npm run build` / `test` / `lint`.

## Gotchas

- <Things that have bitten people. Be specific.>
