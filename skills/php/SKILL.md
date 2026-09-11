---
name: php
description: >
  Modern PHP 8.x rules: strict types, 8.0-8.3 language features, error handling,
  immutability, PSR standards, Composer and PHPUnit.
  Trigger: Writing or reviewing PHP. For Symfony structure, DI, routing or Doctrine ORM, also read `symfony.md` in this skill folder.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# Modern PHP 8.x

> **Symfony / Doctrine work:** read `symfony.md` in this skill folder alongside this file.
> A PHP service living inside a JS monorepo is still Composer-based, not npm — never
> drive its tooling with npm or Nx.

## When to Use

- Writing or reviewing any PHP file.
- Designing PHP classes, value objects, enums or exception hierarchies.
- Setting up Composer, PHPUnit or static analysis for a PHP project.
- For framework work, pair this with `symfony.md` in the same folder.

## Critical Patterns

### Non-negotiables

- **`declare(strict_types=1);` on the first line of every file.** Without it PHP coerces
  silently and your type hints are decoration.
- **Type everything**: parameters, return types, properties. `mixed` is a last resort and
  needs a comment saying why. Never an untyped property.
- **PSR-12** formatting, **PSR-4** autoloading. One class per file; namespace mirrors the
  directory; filename matches the class exactly.
- **No `@` suppression. No `die()`/`exit()` outside a front controller. No `eval`.**
  No `global`. No dynamic property creation (fatal in 8.2+ anyway).

### Use the 8.x language

```php
final class Product
{
    public function __construct(
        public readonly ProductId $id,
        public readonly string $name,
        public readonly ProductStatus $status = ProductStatus::Pending,
    ) {}
}
```

- **Constructor property promotion** — never declare a property and assign it in the body.
- **`readonly`** for anything that must not change after construction. Prefer immutable
  objects with `with*()` methods returning a clone over setters.
- **Backed enums** instead of class constants or magic strings:
  `enum ProductStatus: string { case Pending = 'pending'; … }`. Add behaviour as methods
  on the enum rather than a `switch` at every call site.
- **`match`** over `switch` — it is an expression, strict-compares, and is exhaustive.
- **Named arguments** for calls with booleans or more than three parameters.
- `?->`, `??`, `??=` instead of nested `isset` and `if` pyramids.
- **First-class callables**: `$fn = $this->handle(...)`.
- `never` for functions that always throw; `static` return type for fluent APIs.
- 8.1+ `new` in initializers; 8.3 typed class constants.

### Design

- **`final` by default.** Open a class for extension only when you intend it. Prefer
  composition; inject a collaborator instead of inheriting from it.
- **Program to interfaces** at boundaries — that is what makes the code testable and what
  the container binds.
- **Value objects over primitives.** An `EmailAddress` that validates in its constructor
  cannot be invalid anywhere downstream. Avoid passing bare `string $id` around.
- **No static state.** Static methods are fine as pure factories; static *properties* are
  global mutable state.
- Keep the domain free of framework and infrastructure types.

### Errors

- Throw typed, domain-specific exceptions extending a per-module base
  (`DeviceNotFoundException extends DeviceException`). Never throw `\Exception`.
- Catch narrowly. A bare `catch (\Throwable)` is only acceptable at the outermost
  boundary, and it must log with context and rethrow or map to a response.
- Never return `false`/`null` to signal an error when an exception is the honest answer.
- Guard clauses and early return over nested conditionals.

### Arrays & collections

Typed collection classes or generics-annotated arrays (`@var list<Product>`) over bare
arrays passed between layers. `array_map`/`array_filter` for transformation;
`array_is_list()` when order matters. Never rely on array key order as a contract.

### Composer

Pin with a lockfile and commit it. `require` runtime deps, `require-dev` tooling.
Declare `ext-*` requirements explicitly. Never commit `vendor/`. Run
`composer validate --strict` in CI.

### Testing (PHPUnit)

One behaviour per test, named `testItDoesX`. Arrange/Act/Assert. Use data providers
instead of loops. Mock the interface at the boundary, never the class under test. Test
the exception path, not only the happy path. No test touching a real network or a real
clock — inject both.

### Static analysis

PHPStan or Psalm at the highest level the codebase can hold, raised over time and never
lowered. A baseline is a debt list, not a solution. Fix `php-cs-fixer`/`phpcs` findings
rather than suppressing them.

## Red Flags
A file without `strict_types` · an untyped property or return · `@` suppression · a magic
string where an enum belongs · setters on what should be immutable · `catch (\Throwable)`
mid-stack · `new` of a service inside a domain class · static mutable state · business
logic in a trait · `array` shuttling between layers with no shape.
