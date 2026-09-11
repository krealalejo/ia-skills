---
name: react
description: >
  React 3+ component rules: structure, state ownership, data fetching, performance,
  accessibility and Vitest/RTL testing.
  Trigger: Editing React component code (.tsx/.jsx), hooks, UI state or component tests. Not for Vue (use `vue`), stylesheets (use `css`), or backend code.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# React / TypeScript / Vite

## When to Use

Editing `.tsx`/`.jsx`, writing or reviewing a hook, touching client state, styling, or
component tests. Skip for anything server-side.

## Critical Patterns

### Structure

- One component per file, named export, `PascalCase.tsx`. Colocate `Component.test.tsx`.
- Feature-first: `features/<feature>/{components,hooks,api,types}` — not a global `components/`.
- A component that exceeds ~150 lines or holds more than 3 `useState` calls is doing too
  much: extract a custom hook or split it.
- Props are an explicit `type`, never `any`, never `React.FC` (it hides children semantics).

### State ownership

| Kind of state | Where it belongs |
|---------------|------------------|
| Server data | Query cache (TanStack Query / SWR). **Never** mirror into `useState`. |
| URL-shaped (filters, tabs, page) | The URL / router params. |
| Form input | A form library or one local `useReducer`. |
| Ephemeral UI (open/hover) | Local `useState`, closest to where it is used. |
| Truly global (session, theme) | One context. Split contexts by update frequency. |

Lift state only when a second consumer actually exists. Do not pre-lift.

### Hooks

- Full, honest dependency arrays. Never silence the lint rule — fix the dependency.
- `useEffect` is for **synchronizing with something outside React**. Deriving a value,
  transforming props, or responding to an event is not that. Compute during render.
- Every effect that can outlive the component cleans up (abort, unsubscribe, clear).
- Custom hooks start with `use`, return a stable shape, and own one concern.

### Data fetching

- Fetch in a query hook, never inline in a component body.
- Always handle all four states: loading · error · empty · success. An unhandled empty
  state is a bug, not a detail.
- Validate the response at the boundary (zod). Do not cast an API response to a type.
- Pass an `AbortSignal`; cancel on unmount.

### Performance

Measure before optimizing. In order of payoff: fix the key prop → avoid state that
belongs in a parent → `useMemo`/`useCallback` only for provably expensive work or stable
references across a memo boundary → `React.memo` last. Keys are stable ids, never the
array index when the list can reorder.

### Accessibility

Semantic element first (`<button>`, not a clickable `<div>`). Every input has a label.
Focus is visible and managed on route change and modal open/close. ARIA only when no
native element does the job. Interactive elements reachable and operable by keyboard.

### Testing (Vitest + React Testing Library)

- Query by role and accessible name. `getByTestId` is a last resort.
- Test behaviour the user can observe, never internal state or implementation details.
- `await` every `userEvent` call. Use `findBy*` for async, not arbitrary waits.
- Mock at the network boundary (MSW), not the module under test.

## Red Flags

`useEffect` that only sets state from props · `any` in props · index keys on a reorderable
list · a fetch inside a component body · business logic in JSX · a context that re-renders
the whole tree on every keystroke.
