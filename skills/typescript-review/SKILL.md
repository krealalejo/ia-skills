---
name: typescript-review
description: >
  Review TypeScript code and types using advanced patterns (overloads, generics, utility types, discriminated unions).
  Trigger: /typescript [file] or /typescript (reviews git status).
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

Use this skill to perform a deep technical review of TypeScript code, ensuring type safety, reusability, and adherence to advanced patterns learned in "Advanced TypeScript" classes.

## Critical Patterns

- **Function Overloads**: Use to provide precise signatures for functions that handle multiple input/output combinations.
- **Generics & Constraints**: Always constrain generics using `extends` when specific properties (like `.length`) are required.
- **Type Predicates**: Use `value is Type` in narrowing functions to help the compiler understand custom types.
- **Discriminated Unions**: Use a common property (e.g., `kind` or `type`) to differentiate between union members.
- **Exhaustiveness Checking**: Use the `never` type in `default` blocks of switches to ensure all union cases are handled.
- **Mapped Types**: Use for transforming types (key remapping, filtering, value transformation).
- **Utility Types**: Prefer built-in utilities (`Pick`, `Omit`, `Exclude`, `Record`, `Readonly`, `Partial`, `Required`) over manual type manipulation.
- **React Standards**: Use `React.FC` for components, `PropsWithChildren` for children-enabled props, and `ComponentProps<"tag">` for HTML element extensions.

## Code Examples

### Function Overloads
```typescript
function convertDate(date: Date): number;
function convertDate(date: number): Date;
function convertDate(date: Date | number): Date | number {
  if (typeof date === "number") return new Date(date);
  return date.getTime();
}
```

### Generics with Constraints
```typescript
const getLength = <T extends { length: number }>(value: T): number => value.length;

interface Storage<T> {
  getData(): T;
  setData(value: T): void;
}
```

### Type Predicates & Exhaustiveness
```typescript
function isString(value: unknown): value is string {
  return typeof value === "string";
}

type Shape = Square | Circle;
function area(s: Shape) {
  switch (s.kind) {
    case "square": return s.size * s.size;
    case "circle": return Math.PI * s.radius ** 2;
    default:
      const _exhaustive: never = s;
      return _exhaustive;
  }
}
```

### Mapped & Template Literal Types
```typescript
type Action = "create" | "update";
type EventName<T extends string> = `on_${Action}_${T}`;

type ReadOnly<T> = {
  readonly [P in keyof T]: T[P];
};
```

## Commands

### /typescript [file]
Performs a deep type review of the specified file.

### /typescript
If no file is provided, scans `git status` for modified TypeScript files (`.ts`, `.tsx`) and reviews them.

## Implementation Logic

1. **Scan**: If no argument, run `rtk git status --porcelain` to find `.ts` and `.tsx` files.
2. **Read**: Load the content of the target file(s).
3. **Analyze**: Check against the "Critical Patterns" and "Advanced Class Notes".
4. **Report**: Provide feedback with (1) Problem, (2) Reason (referencing concepts), and (3) Corrected Example.
