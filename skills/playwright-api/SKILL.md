---
name: playwright-api
description: >
  Generates Playwright E2E tests for HTTP API endpoints using the request fixture.
  Triggers: /playwright-api [method] [path] [description].
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- When the user says `/playwright-api` or asks to write a Playwright E2E test for an HTTP API endpoint.
- When the user wants to add test coverage for a REST endpoint using Playwright's `request` fixture.

## Critical Patterns

### Project structure (enforce always)

```
tests/
  e2e/
    api/
      <resource>/
        <resource>.test.ts    # API tests
  support/
    env.ts                    # getBaseUrl(), getTestCredentials()
playwright.config.ts
```

### Rules

- Use Playwright's `request` fixture (or `APIRequestContext`) — no `fetch`, no `axios`.
- Base URL from `process.env.BASE_URL` or `getBaseUrl()` helper.
- One `test.describe` per resource/endpoint group.
- Assert: status code, response body shape, and at least one business-rule invariant.
- For authenticated endpoints: get a token / cookie in `test.beforeAll` and reuse across tests.
- Never assert on exact timestamps or server-generated UUIDs — assert shape and presence only.
- Clean up created resources in `test.afterAll` when the API supports it.
- TypeScript strict mode. No `any` unless wrapping a truly untyped third-party shape.
- `test.skip(condition, 'reason')` for tests that require optional env vars.
- No `test.only` left in committed code (`forbidOnly: true` enforces this on CI).
- Max one `expect` concern per test — split multi-concern assertions into separate `test()` blocks.

## Workflow

1. **Understand the endpoint**: Method, path, auth requirements, request body, expected response.
2. **Check for existing API helpers** in `tests/support/` or a dedicated `tests/api/` support folder.
3. **Scaffold the test file** under `tests/e2e/api/<resource>/<resource>.test.ts`.
4. **Write auth setup** in `test.beforeAll` — call login/token endpoint and store credential.
5. **Write scenarios**: 200 success, auth-required (401), validation error (400/422), not found (404).
6. **Assert response shape** with `expect(response.status()).toBe(...)` and `expect(await response.json()).toMatchObject(...)`.
7. **Teardown**: Delete created resources if the API supports DELETE.

## Code Examples

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
# /playwright-api [method] [path] [description]
#
# Examples:
# /playwright-api                                          # prompts for context
# /playwright-api POST /api/orders                        # infers scenarios from resource name
# /playwright-api POST /api/orders create order with products returns 201
# /playwright-api GET /api/users/:id fetch user by id including 404 case

# Run generated tests:
npx playwright test tests/e2e/api/<resource>/<file>.test.ts --project=e2e

npx playwright show-report
```
