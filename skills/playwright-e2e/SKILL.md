---
name: playwright-e2e
description: >
  Generates Playwright E2E tests following project conventions — web UI tests or API tests.
  Triggers: /playwright-web (browser/UI tests), /playwright-api (HTTP API tests).
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- When the user says `/playwright-web` or asks to write a Playwright E2E test for a web page or UI flow.
- When the user says `/playwright-api` or asks to write a Playwright E2E test for an HTTP API endpoint.
- When the user wants to add test coverage for a new feature, flow, or endpoint using Playwright.

## Critical Patterns

### Project structure (enforce always)

```
tests/
  e2e/
    <feature>/
      <feature>.test.ts       # web UI tests
    api/
      <resource>/
        <resource>.test.ts    # API tests
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

### /playwright-web rules

- Import from `@playwright/test` only.
- Use `gotoAppReady(page, url)` — never bare `page.goto()`. Handles cookie consent + hydration.
- Use relative URLs in `goto` calls so `baseURL` from config is applied.
- Locate elements with `page.getByTestId()` using `data-test-id` attributes. Fall back to `page.getByRole()` or `page.getByText()`. Never use CSS selectors or XPath unless absolutely unavoidable.
- `test.describe` groups related scenarios. One `test()` per user-observable behavior.
- `test.beforeAll` for expensive setup (auth state, fetching dynamic IDs). `test.beforeEach` for per-test navigation.
- Never hardcode IDs or product/resource identifiers — fetch them dynamically or read from env.
- Auth: load `storageState` via `playwright.config.ts` project config. For unauthenticated tests: `test.use({ storageState: { cookies: [], origins: [] } })`.
- `expect.poll()` for conditions that require retrying over time; avoid arbitrary `page.waitForTimeout()`.

### /playwright-api rules

- Use Playwright's `request` fixture (or `APIRequestContext`) — no `fetch`, no `axios`.
- Base URL from `process.env.BASE_URL` or `getBaseUrl()` helper.
- One `test.describe` per resource/endpoint group.
- Assert: status code, response body shape, and at least one business-rule invariant.
- For authenticated endpoints: get a token / cookie in `test.beforeAll` and reuse across tests.
- Never assert on exact timestamps or server-generated UUIDs — assert shape and presence only.
- Clean up created resources in `test.afterAll` when the API supports it.

### General rules (both modes)

- TypeScript strict mode. No `any` unless wrapping a truly untyped third-party shape.
- English only in test descriptions and comments.
- `test.skip(condition, 'reason')` for tests that require optional env vars.
- No `test.only` left in committed code (`forbidOnly: true` enforces this on CI).
- Max one `expect` concern per test — split multi-concern assertions into separate `test()` blocks.

## Workflow

### /playwright-web

1. **Understand the feature**: Ask the user (or read the code) to identify the URL, user action, and expected outcome.
2. **Locate or create support helpers**: Check `tests/support/` for existing locators, navigation helpers, or auth utilities. Reuse before writing new ones.
3. **Scaffold the test file** under `tests/e2e/<feature>/<feature>.test.ts`.
4. **Write setup**: `test.beforeAll` for data, `test.beforeEach` for navigation with `gotoAppReady`.
5. **Write scenarios**: Happy path first, then edge cases (unauthenticated, empty state, error state).
6. **Verify selectors**: Prefer `data-test-id`. If absent, note it and suggest adding the attribute to the component.
7. **Run locally** (if possible): `npx playwright test <file> --project=e2e --headed` to validate.

### /playwright-api

1. **Understand the endpoint**: Method, path, auth requirements, request body, expected response.
2. **Check for existing API helpers** in `tests/support/` or a dedicated `tests/api/` support folder.
3. **Scaffold the test file** under `tests/e2e/api/<resource>/<resource>.test.ts` (or `tests/api/` if the project separates them).
4. **Write auth setup** in `test.beforeAll` — call login/token endpoint and store credential.
5. **Write scenarios**: 200 success, auth-required (401), validation error (400/422), not found (404).
6. **Assert response shape** with `expect(response.status()).toBe(...)` and `expect(await response.json()).toMatchObject(...)`.
7. **Teardown**: Delete created resources if the API supports DELETE.

## Code Examples

### Web test (authenticated flow)

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

### Web test (unauthenticated)

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

### API test

```typescript
import { test, expect } from "@playwright/test";
import { getBaseUrl, getTestCredentials } from "../../support/env";

test.describe("POST /api/orders", () => {
  let authToken: string;

  test.beforeAll(async ({ request }) => {
    const credentials = getTestCredentials();
    test.skip(!credentials, "TEST_EMAIL and TEST_PASSWORD must be set");
    if (!credentials) return;

    const res = await request.post(`${getBaseUrl()}/api/auth/login`, {
      data: { email: credentials.email, password: credentials.password },
    });
    expect(res.ok()).toBeTruthy();
    authToken = (await res.json()).token;
  });

  test("creates order and returns 201", async ({ request }) => {
    const res = await request.post(`${getBaseUrl()}/api/orders`, {
      headers: { Authorization: `Bearer ${authToken}` },
      data: { productId: 123, quantity: 1 },
    });
    expect(res.status()).toBe(201);
    const body = await res.json();
    expect(body).toMatchObject({ id: expect.any(String), status: "pending" });
  });

  test("returns 401 without auth token", async ({ request }) => {
    const res = await request.post(`${getBaseUrl()}/api/orders`, {
      data: { productId: 123, quantity: 1 },
    });
    expect(res.status()).toBe(401);
  });
});
```

## Commands

```bash
# Web UI test — both params optional but recommended:
# /playwright-web [url] [component or flow description]
#
# Examples:
# /playwright-web                                          # prompts for context
# /playwright-web /cart                                   # relative URL, infers flow from page
# /playwright-web https://app.example.com/cart checkout button completes purchase
# /playwright-web /login email/password login shows error on wrong credentials

# API test — method + path recommended, description optional:
# /playwright-api [method] [path] [description]
#
# Examples:
# /playwright-api                                          # prompts for context
# /playwright-api POST /api/orders                        # infers scenarios from resource name
# /playwright-api POST /api/orders create order with products returns 201
# /playwright-api GET /api/users/:id fetch user by id including 404 case

# Run generated tests locally:
npx playwright test tests/e2e/<feature>/<file>.test.ts --project=e2e
npx playwright test tests/e2e/api/<resource>/<file>.test.ts --project=e2e

# Run with browser visible (debug):
npx playwright test <file> --project=e2e --headed

# Show last HTML report:
npx playwright show-report
```
