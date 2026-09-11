# Symfony & Doctrine

> Companion to `SKILL.md` in this directory — read both for Symfony work.
> Modern Symfony (6.4 LTS / 7.x), attribute-driven, autowired.

## Directory structure

```
src/
├── Controller/        thin HTTP adapters, one action per class where it helps
├── Entity/            Doctrine entities — persistence shape only
├── Repository/        query objects; the ONLY place DQL/QueryBuilder lives
├── Service/           application logic (or Domain/ + Application/ if layered)
├── Dto/               request/response payloads, never entities on the wire
├── EventSubscriber/   prefer subscribers to listeners (config lives with the code)
├── Security/          voters, authenticators
├── MessageHandler/    Messenger handlers
└── Command/           console commands — argument parsing only, delegate the work
config/  packages/ · routes/ · services.yaml        templates/  migrations/  tests/
```

`src/` is `App\` via PSR-4. No logic in `public/index.php`.

## Dependency injection

- **Autowire + autoconfigure on.** Constructor injection only. Do not declare a service
  in `services.yaml` unless it needs explicit arguments.
- **Never inject the container.** `ContainerInterface` in a service is a service locator
  and defeats the point. Inject what you use.
- Type-hint the **interface**; bind the implementation once:
  ```yaml
  services:
    App\Domain\Clock: '@App\Infrastructure\SystemClock'
  ```
- Scalars come from bound parameters (`bind: { $apiUrl: '%app.api_url%' }`), never from
  `getenv()` inside a service.
- Many implementations of one interface → a **tagged iterator**, then pick by `supports()`.
  A `match` over a class name means you missed the tag.
- Expensive-to-build collaborators → lazy service, not a manual `new` in the method.
- `#[When('dev')]` / `#[AsEventListener]` / `#[AsMessageHandler]` over YAML wiring.

## Controllers & routing

- **Attribute routing on the action.** No YAML/XML route files. Name every route
  (`name: 'device_show'`) and reference the name, never a hardcoded path.
- **Controllers are adapters.** Map input → call one service → map result to a Response.
  No business logic, no Doctrine queries, no `EntityManager` in a controller.
- `#[MapRequestPayload]` / `#[MapQueryString]` into a typed DTO, with
  `#[Assert\*]` constraints on the DTO. Never read `$request->request->get()` by hand.
- Never accept or return an entity directly — always a DTO. An entity on the wire leaks
  the schema and invites mass assignment.
- Use `#[MapEntity]` deliberately; a 404 from a missing route param should be intentional.
- Return `JsonResponse` with an explicit status; let an exception subscriber map domain
  exceptions to status codes in one place.

## Security

- **Voters for every non-trivial check.** `#[IsGranted('EDIT', subject: 'product')]`.
  Inline `if ($user->getRole() === 'ADMIN')` scattered through controllers is the
  anti-pattern this exists to remove.
- Authorize per resource, not per route. Fail closed on an unknown attribute.
- Never trust `$request` input for identity; take the user from the token storage.
- CSRF on every state-changing form. Validate redirect targets against an allowlist.

## Configuration

`.env` for defaults committed to the repo, `.env.local` never committed, real secrets via
the Symfony secrets vault or SSM/Secrets Manager. No credential in `services.yaml` or any
committed `.env`. Environment-specific config under `config/packages/<env>/`.

## Doctrine

**Mapping**

- Attribute mapping on the entity. Entities are persistence shape — keep domain rules
  out of them where the codebase already separates the two.
- Explicit `#[ORM\Column(type:, nullable:, length:)]`. Never rely on inference.
- `#[ORM\Index]` on every column you filter or sort by, and on every FK you join.
- Enums map with `enumType:`; money as `decimal` (a string in PHP), never `float`.
- Bidirectional relations only when both sides are genuinely traversed. Set
  `cascade` narrowly — never `cascade: ['all']`. `orphanRemoval` only for true composition.

**Querying**

- **All DQL/QueryBuilder lives in a Repository.** Never in a controller or a service.
- **`fetch: 'EXTRA_LAZY'` on large collections**, and solve N+1 with an explicit
  `->addSelect('r')->leftJoin('e.related', 'r')` — not by tuning lazy loading.
  Assume every collection access in a loop is an N+1 until you have proven otherwise.
- Read-only lists select a DTO or an array hydration, not hydrated entities:
  `->select('NEW App\Dto\DeviceListItem(d.id, d.name)')`.
- Always parameterize (`:id`). Interpolating into DQL or SQL is an injection bug.
- Paginate at the query level with `setFirstResult`/`setMaxResults`; never hydrate a
  whole table and slice in PHP.
- Batch processing: `iterate()`/`toIterable()` plus `flush()` + `clear()` every N rows,
  or the identity map will exhaust memory.

**Unit of work**

- **One `flush()` per request**, at the end of the use case — not inside a loop, not
  inside a service that another service also flushes.
- Wrap multi-step writes in `$em->wrapInTransaction(fn () => …)`.
- Optimistic locking via `#[ORM\Version]` for anything concurrently editable.
- Never call `flush()` from an entity, a listener on `postLoad`, or a Twig extension.

**Migrations**

- `doctrine:migrations:diff` then **read and edit the generated SQL**. Never
  `schema:update --force` anywhere, least of all production.
- Migrations are forward-only and reviewed; destructive changes follow expand → migrate →
  contract across separate releases (see the `postgres` skill).
- A migration that drops a column in the same release that stops writing it is a rollback
  trap.

## Messenger & async

Handlers are idempotent — redelivery is normal. Configure a failure transport and a retry
strategy; a handler with neither loses messages silently. Messages are immutable DTOs of
scalars, never entities.

## Testing

`KernelTestCase` for services (real container, mocked boundaries), `WebTestCase` for HTTP.
Use a transactional or throwaway database — never a shared dev one. Factories over
fixtures shared across tests. Assert on the response contract, not on the DOM.

## Commands

```
php bin/console cache:clear · debug:container · debug:router · debug:autowiring
doctrine:migrations:diff | migrate · lint:container · lint:yaml config
```

Run a containerised PHP service through Docker/Composer — never npm or Nx.

## Red flags

`EntityManager` in a controller · `flush()` in a loop · `schema:update` · an entity in a
JSON response · `$container->get()` · `getenv()` in a service · a role string compared
inline · `cascade: ['all']` · a repository method returning a QueryBuilder to a caller ·
raw SQL with interpolated input · a hardcoded URL path · a handler with no retry config.
