---
name: vue
description: >
  Vue 3 rules: Composition API with <script setup>, typed props and emits, composables,
  reactivity correctness, Pinia state and performance.
  Trigger: Editing .vue files, composables, Pinia stores or Nuxt app code. Not for React (use `react`) or framework-free DOM work (use `javascript`).
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# Vue 3 — Composition API

## When to Use

Any `.vue` file, `use*.ts` composable, Pinia store, or Nuxt page/layout. Applies to the
Vue applications and shared Vue packages, including Nuxt and Vuetify projects.

## Critical Patterns

### Component shape

**`<script setup lang="ts">` always.** No Options API in new code, no `defineComponent`
wrapper, no mixins — a mixin's implicit merging is what composables replaced.

```vue
<script setup lang="ts">
const props = withDefaults(defineProps<{ items: Product[]; dense?: boolean }>(), {
  dense: false,
})
const emit = defineEmits<{ select: [id: string]; close: [] }>()
const selected = ref<string | null>(null)
const visible = computed(() => props.items.filter((i) => i.active))
</script>
```

- **Type-based `defineProps`/`defineEmits`.** Never the runtime object form, never
  untyped. `withDefaults` for optional props.
- Order: `<script setup>` → `<template>` → `<style scoped>`. `PascalCase.vue` filenames,
  multi-word (`DeviceList.vue`, never `List.vue`).
- **Never mutate a prop.** Emit and let the owner change it, or copy into local state
  once with an explicit `watch` if it is a seed value.
- `defineModel()` for two-way binding instead of the `modelValue` + `update:modelValue`
  pair written by hand.
- Anything above ~200 lines or with more than one clear responsibility: extract a
  composable (logic) or a child component (markup), not a bigger `<script setup>`.

### Reactivity — where the real bugs are

- **Prefer `ref` over `reactive`.** `reactive` breaks on destructuring and reassignment;
  `ref` is uniform and survives both. Use `reactive` only for a fixed, never-reassigned
  object.
- **Destructuring kills reactivity.** `const { items } = props` is a snapshot. Use
  `toRefs(props)` or just reference `props.items`. Same for a store: `storeToRefs()`.
- `computed` for derived values — **always**. A `watch` that sets another ref is almost
  always a `computed` written wrong.
- `watch` for side effects on a *specific* source, with an explicit source and
  `{ immediate }` only when you mean it. `watchEffect` only when the dependency set is
  genuinely dynamic; it re-runs on things you did not intend surprisingly often.
- Use `{ flush: 'post' }` when the effect reads the DOM.
- `shallowRef` for large immutable payloads and third-party instances (a map, a chart, an
  editor) — deep reactivity on those is pure cost and sometimes breaks the library.
- Never store a component instance or a DOM node in a deep `ref`.

### Composables

- `use*` name, one concern, in `composables/` or the feature folder.
- Return **refs and computeds**, not plain unwrapped values, or the caller loses
  reactivity. Return an object, not an array.
- Accept `MaybeRefOrGetter<T>` and normalise with `toValue()` so callers can pass either.
- **Clean up what you create**: `onScopeDispose` (or `onUnmounted`) for every listener,
  interval, observer and subscription. A composable that leaks is worse than inline code.
- No module-level mutable state inside a composable — that is an accidental singleton
  shared across every component and every SSR request. If you want a singleton, use Pinia.
- Composables are called synchronously at setup top level. Never inside a conditional,
  a loop, or after an `await`.

### State management

| State | Where |
|-------|-------|
| Server data | A query library (TanStack Query) or a Nuxt `useAsyncData`/`useFetch`. Do not mirror it into a store. |
| Shared client state | Pinia, setup-store syntax |
| Route-shaped (filters, tabs, page) | The URL |
| Local UI | `ref` in the component |
| Cross-cutting config | `provide`/`inject` with an `InjectionKey<T>` |

```ts
export const useProductStore = defineStore('product', () => {
  const items = ref<Product[]>([])
  const active = computed(() => items.value.filter((d) => d.active))
  async function load() { items.value = await api.list() }
  return { items, active, load }
})
```

- Setup stores over options stores. Destructure with `storeToRefs`, call actions directly.
- One store per domain. A `useAppStore` holding everything is a global object.
- Never mutate store state from a component — go through an action.
- `provide`/`inject` needs a typed `InjectionKey`; a bare string key is untyped and
  collides.

### Templates

- `:key` on every `v-for`, a stable id — never the index when the list can reorder.
- **Never `v-if` and `v-for` on the same element.** Filter in a `computed`.
- Keep expressions trivial. Anything with a ternary chain or a method call per row
  belongs in a `computed`.
- `v-show` for frequent toggling, `v-if` for rarely-rendered branches.
- `v-html` only with content you generated. With API or user data it is an XSS hole.
- Prefer named slots with typed `defineSlots<T>()` over passing render config as props.

### Performance

Measure first. Then: `shallowRef` for big payloads, `defineAsyncComponent` for
route-level chunks, `v-memo` for genuinely hot lists, virtual scrolling past a few
hundred rows. `v-once` for static blocks. Do not reach for `markRaw` unless profiling
says deep reactivity is the cost.

### Style

`<style scoped>` by default. Tokens and BEM per the `css` skill. `:deep()` sparingly and
with a comment — it couples you to a child's internals. In Vuetify projects, theme
through the Vuetify theme config, not by overriding its classes.

### Testing (Vitest + @vue/test-utils / Testing Library)

Query by role and accessible name. Test rendered behaviour and emitted events, never
internal refs. `await nextTick()` or `findBy*` after an interaction — no arbitrary
timeouts. Mock at the network boundary (MSW), not the composable under test. Test a
composable directly where it has no template.

## Red Flags
Destructured props · `reactive` reassigned · a `watch` that only derives a value ·
mutating a prop · module-level `ref` in a composable · `v-if` with `v-for` · index keys ·
`storeToRefs` missing · store state mutated from a component · a composable with no
cleanup · `v-html` on API data · `any` in `defineProps` · Options API in new code.
