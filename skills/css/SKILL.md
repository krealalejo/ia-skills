---
name: css
description: >
  CSS rules: strict BEM naming, mobile-first responsive design, custom properties and
  theming, modern layout and specificity discipline.
  Trigger: Writing or reviewing any stylesheet, <style> block, scoped component styles or design tokens.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# CSS — BEM, mobile-first, custom properties

## When to Use

Writing or reviewing any stylesheet or component `<style>` block.

## Critical Patterns

### BEM — non-negotiable naming

```
.block                     standalone, meaningful on its own      .card
.block__element            a part, meaningless outside the block  .card__title
.block--modifier           a variant of the whole block           .card--featured
.block__element--modifier  a variant of a part                    .card__title--muted
```

Rules, no exceptions:

1. **One underscore pair, one hyphen pair.** `__` separates element, `--` separates
   modifier. Words inside a name use a single hyphen: `.search-form__input-label`.
2. **No element of an element.** `.card__body__title` is forbidden — BEM is flat, not a
   DOM mirror. Nesting in the markup does not mean nesting in the name: use `.card__title`.
   If a part genuinely needs its own parts, it is its own block.
3. **A modifier never stands alone.** Always `class="card card--featured"`. Styling
   `.card--featured` without `.card` present is a bug.
4. **Style classes, not elements or ids.** No `.card h2`, no `#header`, no
   `div.card`. One class, one flat selector, specificity `0-1-0` everywhere.
5. **A block never sets its own outer geometry.** No `margin`, `position`, `width`, or
   `grid-area` on `.card` itself — the *parent* positions it (`.grid__item`, or a layout
   class). This is what makes a block reusable in a second context.
6. **Nesting limit: one level**, and only for a state or media query. If you use Sass
   `&__`, keep the full name greppable or you lose the one real benefit of BEM.

State goes on a modifier or a `data-*`/`aria-*` attribute (`[aria-expanded="true"]`),
never a bare `.active` floating in the global namespace.

### Mobile-first

- Base styles are the **smallest** screen. No media query.
- Add complexity upward with `min-width` only. **Never `max-width`** — mixing directions
  creates overlapping ranges nobody can reason about.
- Breakpoints are named tokens, not magic numbers, and are chosen where the *layout*
  breaks, not to match a device.
- Prefer no breakpoint at all: `clamp()`, `minmax()`, `auto-fit` and flex wrapping solve
  most of this without a query.

```css
.card { padding: var(--space-3); }
@media (min-width: 48rem) { .card { padding: var(--space-5); } }
```

- Media queries in `rem`, not `px` — they respect the user's font size.
- Also honour `prefers-reduced-motion` and `prefers-color-scheme`; they are not optional.

### Custom properties

- **Tokens on `:root`.** Everything else consumes them. A raw hex, a raw `px` spacing
  value, or a raw font stack outside `:root` is a bug.
- Scale, not arbitrary values: `--space-1 … --space-8`, `--font-size-sm … -xl`.
- Semantic layer on top of the primitive layer: `--color-surface: var(--gray-50)`.
  Components reference the semantic name, so theming changes one line.
- Theme by redefining tokens on a scope, never by overriding component rules:

```css
:root { --color-surface: #fff; --color-text: #1a1a1a; }
:root[data-theme="dark"] { --color-surface: #121212; --color-text: #f2f2f2; }
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) { --color-surface: #121212; --color-text: #f2f2f2; }
}
```

- Custom properties inherit and are dynamic — use them for per-instance values
  (`.card { --card-cols: 2 }`) instead of adding a modifier for every number.
- Give a fallback where a token may be absent: `var(--x, 1rem)`.

### Layout & units

Grid for two dimensions, flex for one. Logical properties (`margin-inline`,
`padding-block`, `inset`) over physical ones. `gap` instead of margin hacks between
children. `rem` for type and spacing, `px` only for hairlines and borders, `ch` for
measure. Never set `font-size` in `px`.

### Specificity

Keep every selector at one class. No `!important` (except to override a third-party
inline style, with a comment saying which). No ID selectors. No qualifying a class with a
tag. If you need to win a specificity fight, the markup is wrong, not the selector.

## Red Flags
`.block__el__el` · a lone `.active` · `max-width` media queries · a hex or `px` spacing
outside `:root` · `!important` · an ID selector · `margin` on a block root · `font-size`
in `px` · a breakpoint named after a phone · deep descendant selectors · theming by
overriding component rules instead of tokens.
