# Lesson 3: teacher guide and answers

Based on the supplied Romanian Lesson 3 slides and homework: Redis cache-aside, 60-second TTL, invalidation, Swagger/JWT, and feature-branch PRs. The documents define classroom exercises; they do not authorize repository protection changes or external review requests.

## 40-minute plan

| Minutes | Together |
| --- | --- |
| 0-5 | Start PostgreSQL and Redis; finish any Lesson 2 auth gaps. |
| 5-15 | Explain miss/hit and keys. Complete L3-1/L3-2; inspect Redis TTL. |
| 15-23 | Complete L3-3/L3-4. Change a product and prove stale values are removed. |
| 23-30 | Complete L3-5/L3-6; use Swagger Authorize and show 401/403/200. |
| 30-40 | Run checks, create a feature branch, commit, push, and review a PR. |

Dependencies, typed JSON serialization, TTL, route access and most Swagger annotations are prepared. `ProductService.categories()` serves the role of the slides' separate CategoryService to avoid an extra class. Redis is disabled by default for earlier lessons; enable it as described in [database setup](../database/README.md#lesson-3-redis-optional-for-earlier-lessons).

## Answer key

**L3-1**, above `ProductService.list`:

```java
@Cacheable(cacheNames = "products", key = "#categoryId != null ? #categoryId : 'all'")
```

**L3-2**, above `ProductService.categories`:

```java
@Cacheable(cacheNames = "categories", key = "'all'")
```

**L3-3**, above each of `create`, `update`, and `delete`:

```java
@CacheEvict(cacheNames = "products", allEntries = true)
```

Keep `@Transactional`. The Redis manager is transaction-aware, so invalidation is applied after commit. Clear every category variant, since a product can move categories.

**L3-4**, replace the placeholder method in `CatalogCacheService`:

```java
@CacheEvict(cacheNames = {"products", "categories"}, allEntries = true)
public void clear() { }
```

**L3-5**, after `Components components = new Components();`:

```java
components.addSecuritySchemes("bearerAuth", new SecurityScheme()
        .type(SecurityScheme.Type.HTTP)
        .scheme("bearer")
        .bearerFormat("JWT"));
```

**L3-6**, above the product GET route:

```java
@Operation(summary = "List products, optionally filtered by category")
```

Review the prepared `@Tag`, `@ApiResponse` and protected-route `@SecurityRequirement` annotations. An empty product result is 200 with `[]`, not 404. Swagger login/register remain public; protected routes carry `bearerAuth`.

## Verification and design notes

Follow [the student checklist](../LESSON3_CHECKLIST.md). `setup check` uses an in-memory cache plus repository spies to verify hits, independent keys, all three write invalidations, manual clearing and OpenAPI. Separate tests verify the Redis serialization and 60-second TTL configuration. Students must also inspect a running Redis server; an in-memory test does not prove Redis connectivity.

Only public product/category DTOs are cached. No passwords, tokens or JPA entities enter Redis. Keys are `products::all`, `products::<id>` and `categories::all`. The prefix and cache names are shared by the two reference branches; clear the catalog caches when switching branches against the same Redis instance.

The supplied frontend calls cache clear without a token. `/api/cache/clear` is therefore public in this localhost-only classroom app, and touches only the two catalog caches, never FLUSHALL or the database. In an externally deployed app, restrict it and update the frontend auth flow. When caching is disabled, a completed clear action is a no-op. With Redis enabled but unavailable, cache access returns 503 with an actionable message.

TTL limits stale data but is not a full concurrency guarantee: a read overlapping a write can briefly repopulate stale data. This lesson demonstrates basic cache-aside, not distributed consistency.

## Homework review

Check that the student used their own feature branch and PR, reviewed the full diff, and documented success and error responses. Confirm their screenshots show keys and TTL, not only frontend timing. The reference answer is on `solution`; `main` retains numbered exercises. Add future lessons using the existing `lesson-complete` test tag and shared check command.
