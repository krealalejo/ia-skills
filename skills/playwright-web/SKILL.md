---
name: playwright-web
description: >
  Generates Playwright E2E tests for web UI flows and browser interactions.
  Triggers: /playwright-web [url] [flow description].
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- When the user says `/playwright-web` or asks to write a Playwright E2E test for a web page or UI flow.
- When the user wants test coverage for a feature, navigation flow, or UI interaction using Playwright.

## Critical Patterns

### Project structure (enforce always)

```
tests/
  e2e/
    <feature>/
      <feature>.test.ts       # web UI tests
  support/
    env.ts                    # getBaseUrl(), getTestCredentials()
    navigation.ts             # gotoAppReady() — always use instead of bare page.goto()
    auth/
      login.ts
playwright/
  .auth/
    storageState.json         # gitignored
playwright.config.ts
```

### Rules

- Import from `@playwright/test` only.
- Use `gotoAppReady(page, url)` — never bare `page.goto()`. Handles cookie consent + hydration.
- Use relative URLs in `goto` calls so `baseURL` from config is applied.
- Locate elements with `page.getByTestId()` using `data-test-id` attributes. Fall back to `page.getByRole()` or `page.getByText()`. Never use CSS selectors or XPath unless absolutely unavoidable.
- `test.describe` groups related scenarios. One `test()` per user-observable behavior.
- `test.beforeAll` for expensive setup (auth state, fetching dynamic IDs). `test.beforeEach` for per-test navigation.
- Never hardcode IDs or product/resource identifiers — fetch them dynamically or read from env.
- Auth: load `storageState` via `playwright.config.ts` project config. For unauthenticated tests: `test.use({ storageState: { cookies: [], origins: [] } })`.
- `expect.poll()` for conditions that require retrying over time; avoid arbitrary `page.waitForTimeout()`.
- TypeScript strict mode. No `any` unless wrapping a truly untyped third-party shape.
- `test.skip(condition, 'reason')` for tests that require optional env vars.
- No `test.only` left in committed code (`forbidOnly: true` enforces this on CI).
- Max one `expect` concern per test — split multi-concern assertions into separate `test()` blocks.

## Context hints (user should provide)

```
unit-tests:       path to unit/component tests for the feature
components:       path to source components
known-selectors:  any data-test-id values already known
async-anchors:    known loading indicators (loaders, spinners, disabled states)
```

Use whatever the user provides. Prompt for missing hints only if they are needed and cannot be discovered from the codebase.

## Pre-research phase (always before writing)

Do this before writing a single line of test code. Document findings inline as comments above the first `test.describe`.

1. **Map selectors**: `grep -r "data-test-id" <component-dir>` — list every testable selector for the feature. If `components:` hint given, start there.
2. **Read unit/component tests**: extract component lifecycle, fired events, store interactions, and edge-case branches already covered. If `unit-tests:` hint given, read those files.
3. **Read the store**: find the feature's store/state file → identify async loading states and their DOM signals (loading flags, error flags, empty states).
4. **Identify timing anchors**: what element appears or disappears when async ops complete? This becomes the `await expect(...)` gate before each assertion.
5. **Map lazy boundaries**: which parts of the UI are eager vs deferred/accordion? Tests must not assert on content that hasn't loaded yet.

Output of pre-research (document inline):

```typescript
// Pre-research summary:
// Selectors found: #list-item, #submit-btn, #error-banner
// Async anchor: [data-test-id="loading-spinner"] disappears → content ready
// Store: useFooStore — loadFoo() sets isLoading, items[], error
// Lazy: accordion panel deferred until user expands
// Unit tests cover: empty state, error state → E2E adds: happy path, navigation
```

## Workflow

1. **Collect context**: use `unit-tests:`, `components:`, `known-selectors:`, `async-anchors:` hints if provided; otherwise discover from codebase.
2. **Run pre-research phase**: complete all 5 steps above before writing any test code.
3. **Locate or create support helpers**: check `tests/support/` for existing navigation helpers or auth utilities. Reuse before writing new ones.
4. **Scaffold the test file** under `tests/e2e/<feature>/<feature>.test.ts`.
5. **Write setup**: `test.beforeAll` for data, `test.beforeEach` for navigation with `gotoAppReady`.
6. **Write scenarios**: happy path first (use timing anchor as gate), then edge cases not already covered by unit tests (unauthenticated, empty state, error state).
7. **Verify selectors**: prefer `data-test-id`. If absent, note it and suggest adding the attribute to the component.
8. **Run locally** (if possible): `npx playwright test <file> --project=e2e --headed` to validate.

## Code Examples

### Authenticated flow

```typescript
import { test, expect } from "@playwright/test";
import { gotoAppReady } from "../../support/navigation";

test.describe("Checkout Flow", () => {
  test.beforeEach(async ({ page }) => {
    await gotoAppReady(page, "/cart");
  });

  test("shows empty cart message when no items added", async ({ page }) => {
    await expect(page.getByTestId("empty-cart-message")).toBeVisible();
  });

  test("proceeds to payment when cart has items", async ({ page }) => {
    await page.getByTestId("checkout-button").click();
    await expect(page).toHaveURL(/\/checkout/);
  });
});
```

### Unauthenticated flow

```typescript
import { test, expect } from "@playwright/test";
import { gotoAppReady } from "../../support/navigation";

test.describe("Login Page", () => {
  test.use({ storageState: { cookies: [], origins: [] } });

  test("redirects to login when accessing protected route", async ({
    page,
  }) => {
    await gotoAppReady(page, "/dashboard");
    await expect(page).toHaveURL(/\/login|\/connexion/);
  });
});
```

## Commands

```bash
# /playwright-web [url] [flow description]
#
# Examples:
# /playwright-web                                          # prompts for context
# /playwright-web /cart                                   # relative URL, infers flow from page
# /playwright-web /cart checkout button completes purchase
# /playwright-web /login email/password login shows error on wrong credentials

# Run generated tests:
npx playwright test tests/e2e/<feature>/<file>.test.ts --project=e2e
npx playwright test <file> --project=e2e --headed   # with browser visible

npx playwright show-report
```
