# Lesson 3: Redis, Swagger and Git

First finish Lesson 2, start PostgreSQL, and [enable Redis](database/README.md#lesson-3-redis-optional-for-earlier-lessons).

Search for `TODO Lesson 3`. Java files are under `src/main/java/com/impact/ecommerce/`.

| Done | TODO | File | Task |
| --- | --- | --- | --- |
| [ ] | L3-1 | services/ProductService.java | Enable product caching with separate keys for all products and each category. |
| [ ] | L3-2 | services/ProductService.java | Enable category caching. |
| [ ] | L3-3 | services/ProductService.java | Evict all product lists after create, update AND delete. |
| [ ] | L3-4 | services/CatalogCacheService.java | Enable clearing both caches and remove the placeholder throw. |
| [ ] | L3-5 | config/OpenApiConfig.java | Add the JWT `bearerAuth` security scheme. |
| [ ] | L3-6 | controllers/CatalogController.java | Complete the product-list summary; review every route's responses. |

## Prove it works

1. Run `.\setup.cmd check` (Windows) or `bash setup.sh check` (Mac/Linux). These checks do not need Redis; complete all included lesson TODOs first.
2. Start the app. Open **http://localhost:8080/swagger-ui/index.html** and **http://localhost:8080/v3/api-docs**.
3. In Swagger, log in as `admin@impact.md` / `admin123`. Copy `token`, click **Authorize**, paste the token without `Bearer`, and try `/api/admin/test`.
4. Request `/api/products` twice. Inspect Redis: `redis-cli --scan --pattern 'products::*'`, then `redis-cli TTL products::all` (between 1 and 60 seconds).
5. Request `/api/categories` twice. Inspect `categories::all` too.
6. `POST /api/cache/clear`; cached keys disappear, PostgreSQL data stays. The next read repopulates Redis.
7. Create/update/delete a product as ADMIN. All product-cache keys must disappear after each successful write.

On Windows, use `memurai-cli` instead of `redis-cli`. Docker commands are in the database guide. Timing alone is not proof: use keys, TTL and the tests. TTL expiry removes a key even without a write.

## Submit your homework

Run in **your own template repository**:

```sh
git switch main
git pull --ff-only origin main
git switch -c feature/l3-redis-cache
# Complete the TODOs, then:
git add .
git commit -m "feat: add Redis caching and Swagger"
git push -u origin feature/l3-redis-cache
```

On GitHub, open a PR to your `main`. Read the entire diff, ask a classmate for review, and merge after checks pass. Include screenshots of Swagger Authorize, Redis keys/TTL, and before/after cache clearing. Teacher reference: `solution` branch.
