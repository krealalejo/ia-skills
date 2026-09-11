---
name: javascript
description: >
  Vanilla JavaScript (ES2020+) rules: ES modules, clean DOM manipulation, event
  delegation, async patterns and framework-free architecture.
  Trigger: Writing plain .js/.mjs with no framework - widgets, progressive enhancement, browser or build scripts. Not for React/Vue component code.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# Vanilla JavaScript (ES2020+)

## When to Use

Plain `.js`/`.mjs` with no framework: embeddable widgets, progressive enhancement,
build scripts, browser utilities. If a framework owns the render loop, use its skill.

## Critical Patterns

### Modules

- **ESM only.** `import`/`export`. No `var`, no IIFE namespacing, no globals on `window`.
- **Named exports.** Default exports rename freely at the import site and break grep.
- One concern per module; the filename says what it owns (`dom.js`, `format-date.js`).
- Side-effect-free at import time. A module that mutates the DOM when imported cannot be
  tested or tree-shaken. Export an `init()` and let the caller decide.
- Circular imports are a design error, not a bundler problem — extract the shared piece.

### Language

- `const` by default, `let` when reassigned. `var` never.
- `?.` and `??` instead of `&&` chains and `||` (which swallows `0` and `''`).
- Destructure at the boundary: `function draw({ width, height = 100 })`.
- `for…of` and array methods over index loops. `map`/`filter`/`reduce` only where they
  read better than a loop — a `reduce` building an object is usually a worse `for…of`.
- `structuredClone()` over hand-rolled deep copies; spread is shallow, know that.
- `Map` for non-string keys and ordered iteration, `Set` for membership, plain objects
  only for fixed-shape records.
- Template literals over concatenation. Never build HTML by concatenating user input.

### DOM

- Query once, cache the reference. Never re-query inside a loop or a scroll handler.
- **`textContent` for text, always.** `innerHTML` only with a string you built yourself
  from literals — never with user, URL, or API data. That is an XSS bug, not a style issue.
- Build nodes with `document.createElement` or `<template>` + `cloneNode(true)`.
  Batch insertions through a `DocumentFragment`; one reflow instead of N.
- State lives in JS, not in the DOM. Read `data-*` for configuration; do not use class
  names or DOM structure as your source of truth.
- Toggle behaviour with `classList.toggle(name, boolean)` and `el.hidden`, not inline
  `style.display`.
- Batch reads then writes. Interleaving `offsetHeight` with style writes causes layout
  thrash — measure everything first, mutate second.

### Events — delegate

One listener on a stable ancestor, not N listeners on N children. Survives re-rendered
content and costs one registration.

```js
list.addEventListener('click', (e) => {
  const btn = e.target.closest('[data-action="remove"]');
  if (!btn || !list.contains(btn)) return;
  remove(btn.dataset.id);
});
```

- Always guard with `closest()` + a `contains()` check — `e.target` is the deepest node.
- **`AbortController` for teardown.** Pass `{ signal }` to every `addEventListener` and
  call `controller.abort()` once; no listener bookkeeping, nothing leaks.
- `{ passive: true }` on `scroll`/`touchstart` unless you actually call `preventDefault`.
- Components communicate upward with `CustomEvent` + `detail`, never by reaching into a
  parent. Extend `EventTarget` for a non-DOM emitter.

### Async

- `async`/`await` with `try`/`catch`. No `.then()` chains, no callbacks.
- Independent work runs concurrently: `await Promise.all([...])`. Awaiting in a loop when
  the iterations are independent is a bug. `Promise.allSettled` when partial failure is OK.
- Every `fetch` gets an `AbortController` signal and is aborted on teardown.
- `fetch` does **not** reject on 4xx/5xx — check `res.ok` explicitly, every time.
- Never leave a promise floating: `await` it, or `.catch()` it deliberately.

### Performance

Debounce input, throttle scroll/resize. `requestAnimationFrame` for anything visual —
never a timer. `IntersectionObserver` for visibility, `ResizeObserver` for size, instead
of polling in a scroll handler. Prefer CSS transitions over JS-driven animation.

## Red Flags
`innerHTML` with dynamic data · a listener added per list item · reading state out of a
class name · `await` inside a loop over independent items · no `res.ok` check · a global
on `window` · `var` · `==` · a module that mutates the DOM on import · `setTimeout(…, 0)`
used to "wait for the DOM".
