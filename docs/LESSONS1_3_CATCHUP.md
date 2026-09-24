# Lessons 1-3: from the starter to the solution

Use this guide during the catch-up lesson. Read the structure first, then work through the code changes in order. Each change includes what it does and where it goes.

This guide matches the Lesson 3 version of this repository. Start from **main**. **solution** already contains these answers. Later lessons may add more files and exercises.

## 1. Understand the project before editing

### What are we building?

The **frontend** is the page a person sees. The **backend** is the Java program that handles requests from that page. **PostgreSQL** stores permanent data. **Redis** stores temporary copies of public catalog responses to make repeated reads faster.

An **API endpoint** is a URL plus an HTTP method. For example, `GET /api/products` means "give me the product list"; `POST /api/products` means "create a product".

A **request** travels to the backend. A **response** travels back, usually as JSON. JSON is text containing named values, such as `{"name":"Book","price":10}`.

### How the folders fit together

```text
Browser / Postman / Swagger
          |
          v
Security filter -- checks a supplied JWT and identifies the user
          |
          v
Controller -- chooses the Java method for the requested URL
          |
          v
Service -- applies the rules and prepares a response
          |
          +---- Redis: return a cached catalog response if present
          |
          v
Repository -- reads/writes database rows
          |
          v
PostgreSQL

The response travels back through the service and controller.
```

A **class** groups data and behavior. A **method** is a named action inside a class. A **package** groups related Java files.

Spring creates and connects application objects for us. For example, the `ProductService` constructor asks for repositories; Spring supplies them. We do not manually create a service every time a request arrives.

### Root files and supporting folders

| File or folder | Purpose |
| --- | --- |
| `pom.xml` | Maven's project recipe: Java 21, libraries, packaged resources and test settings. |
| `setup.cmd` | Windows entry point: setup, run, database or checks. |
| `setup.sh` | Mac/Linux entry point; selects the correct platform script. |
| `scripts/setup-windows.ps1` | Windows tool installation, frontend update, build and run commands. |
| `scripts/setup-macos.sh` | macOS entry point for the shared shell helpers. |
| `scripts/setup-debian.sh` | Debian entry point for those same helpers. |
| `scripts/setup-common.sh` | Shared Mac/Debian setup, run, database and test functions. |
| `scripts/CheckPom.java` | Checks the Maven XML and repairs the known misplaced-dependency mistake when safe. |
| `scripts/tests/test_setup.py` | Tests setup helpers with disposable Git repositories. |
| `.gitignore` | Lists local files Git should leave untracked, such as passwords, build output and frontend. Already tracked files remain tracked. |
| `.gitattributes` | Keeps line endings suitable for Windows and shell scripts. |
| `README.md` | Short startup instructions and lesson links. |
| `LESSON1_CHECKLIST.md`, `LESSON2_CHECKLIST.md`, `LESSON3_CHECKLIST.md` | Student tasks and checks for each lesson. |
| `docs/LESSON1_TEACHER.md`, `docs/LESSON2_TEACHER.md`, `docs/LESSON3_TEACHER.md` | Individual lesson plans and answer keys. |
| `docs/LESSONS1_3_CATCHUP.md` | This combined walkthrough. |
| `frontend/` | Separate frontend checkout. Its `index.html` is served by Java. Leave its code and Git remote alone. |
| `target/` | Generated classes, packaged application and test reports. Maven rebuilds it; don't edit it. |
| `.git/` | Git's history and branch information; don't edit it manually. |

### Database and settings files

| File | Purpose |
| --- | --- |
| `database/create_database.sql` | Creates the PostgreSQL database named `e-commerce` when missing; run using psql. |
| `database/create_tables.sql` | Creates missing `users`, `categories` and `products` tables. Does not automatically upgrade existing columns. |
| `database/insert_data.sql` | Adds sample products, categories and classroom accounts without resetting matching existing records. |
| `database/compose.yaml` | Optional Docker PostgreSQL; optional Lesson 3 Redis profile. Native services also work. |
| `database/README.md` | Native/Docker database and Redis setup instructions. |
| `database/application-local.properties.example` | Template for your local database settings. |
| `application-local.properties` | Your local passwords and optional Redis settings; ignored by Git. |
| `src/main/resources/application.properties` | Shared ports, database defaults, SQL initialization, JWT and Redis settings. SQL runs before JPA validates the tables. |
| `src/test/resources/application-test.properties` | Isolated H2 database settings for automated tests. Tests do not modify classroom PostgreSQL. |

### Every Java file and its job

All paths in this table start at `src/main/java/com/impact/ecommerce/`.

| File | Purpose |
| --- | --- |
| `Lesson1BackendApplication.java` | The Java entry point that starts Spring Boot. Its old name does not limit it to Lesson 1. |
| `config/CorsConfig.java` | Which browser origins, HTTP methods and headers may call the API. CORS is not a login system. |
| `config/SecurityConfig.java` | Which routes are public, need login, or require ADMIN. Also supplies BCrypt and installs the JWT filter. |
| `config/CacheConfig.java` | Enables Spring caching and configures typed Redis JSON, a 60-second lifetime and eviction after successful transactions. |
| `config/OpenApiConfig.java` | API title and the JWT scheme used by Swagger's Authorize button. |
| `controllers/PracticeController.java` | The five Lesson 1 request/response exercises. |
| `controllers/AuthController.java` | Registration/login URLs; validates input and calls AuthService. |
| `controllers/CatalogController.java` | Product/category reads and ADMIN product writes. Includes Swagger descriptions. |
| `controllers/TestController.java` | Small authenticated and ADMIN routes for checking permissions. |
| `controllers/CacheController.java` | `POST /api/cache/clear`; asks the cache service to clear catalog caches. |
| `services/AuthService.java` | Registration rules, duplicate emails, password hashing/checking and auth responses. |
| `services/ProductService.java` | Lists, filters, maps, creates, updates and deletes products; also lists categories. Caching belongs here. |
| `services/CatalogCacheService.java` | Clears only product/category caches through Spring's caching annotations. |
| `repositories/UserRepository.java` | Finds users by email and checks whether an email already exists. |
| `repositories/ProductRepository.java` | Product storage, category filtering and name queries. Spring implements the repository interface. |
| `repositories/CategoryRepository.java` | Category storage and lookup. |
| `entities/User.java` | Maps a user row: ID, email, password hash, role and creation time. |
| `entities/Role.java` | The allowed roles: USER and ADMIN. |
| `entities/Product.java` | Maps a product row and its optional category relationship. Uses BigDecimal for prices. |
| `entities/Category.java` | Maps a category row: ID and name. |
| `dtos/auth/RegisterRequest.java` | Allowed registration fields and validation rules. Does not accept an ADMIN role. |
| `dtos/auth/LoginRequest.java` | Email/password input and validation rules for login. |
| `dtos/auth/AuthResponse.java` | The returned token, user ID, email and role. No password hash. |
| `dtos/product/CreateProductRequest.java` | Validated input for creating/updating a product. |
| `dtos/product/ProductResponse.java` | Public product JSON. Includes category ID/name and a `category` alias for the frontend. |
| `dtos/product/CategoryResponse.java` | Public category ID/name JSON. |
| `security/JwtService.java` | Signs tokens and verifies their signature/expiry. A signed JWT is not encrypted; never put passwords in it. |
| `security/JwtFilter.java` | Reads `Authorization: Bearer <token>`, validates it, loads the user's role and identifies the current request. |
| `exceptions/ApiExceptionHandler.java` | Converts known failures into clear JSON error responses and HTTP status codes. |
| `exceptions/LessonTodo.java` | Returns 501 for unfinished exercises. Remove the placeholder call when implementing that task. |
| `package-info.java` files | Package-level comments. They do not execute code; some still describe the earlier empty scaffold. |

An **entity** represents database data. A **DTO** is a small object describing what may cross the API boundary. We use DTOs so database internals and password hashes don't accidentally become API responses.

### Test files

These live under `src/test/java/com/impact/ecommerce/`.

| File | What it proves |
| --- | --- |
| `Lesson1BackendApplicationTests.java` | Frontend serving, practice route and private-file protection. The solution adds exact response and CORS checks. |
| `Lesson2Tests.java` | Validation, password rules, registration, JWT and permissions. Completion tests are tagged `lesson-complete`. |
| `Lesson3Tests.java` | Swagger, Redis DTO serialization/TTL configuration, cache hits and invalidation. Cache behavior tests use an in-memory cache; live Redis must also be checked. |

### Java/Spring notation you will see

| Notation | Meaning here |
| --- | --- |
| `@RestController` | This class handles HTTP requests. |
| `@GetMapping` / `@PostMapping` | This method handles a particular URL and HTTP action. |
| `@Service` | Application rules live in this Spring-managed object. |
| `@Entity` | This class maps to a database table. |
| `@Valid` | Check the request's validation rules before running the controller method. |
| `@Transactional` | Group database work into a transaction: commit successfully or roll back. |
| `@Cacheable` | Return a cached value on a hit; otherwise run the method and cache its result. |
| `@CacheEvict` | Remove cached values after a successful call. |
| `@Operation` / `@ApiResponse` | Describe an endpoint and its possible responses in Swagger. |
| `return` | Finish a method and give its result to the caller. |
| `throw` | Stop normal execution with an error. |
| `null` | No value was supplied or no related object exists. |

## 2. Prepare once before the fast lesson

Budget about **60-75 minutes for the walkthrough after tools and databases are ready**. Installation can take longer; do it before class.

1. Work in your own template repository, starting from `main`. Create a feature branch before editing.
2. Run setup once: double-click `setup.cmd` or run `bash setup.sh`.
3. Follow [database setup](../database/README.md): start PostgreSQL, create `e-commerce` and set your local password.
4. Keep Redis disabled initially: `spring.cache.type=none` in `application-local.properties`.
5. Start with `.\setup.cmd run` or `bash setup.sh run`. Open `http://localhost:8080/`.
6. Stop with Ctrl+C and restart after each group of edits. There is no automatic Java reload configured.

The tables/sample data are prepared on startup. GET products should work before the exercises are finished. Registration/login will not work until the relevant Lesson 2 TODOs are completed.

## 3. Lesson 1: requests, responses and CORS (10 minutes)

**All short Java paths below start at `src/main/java/com/impact/ecommerce/`.**
Replace the shown code inside the existing class. Do not paste a second method with the same name. Keep the prepared imports, mappings and Swagger annotations unless told otherwise.

### 3.1 Allow the lesson's browser requests

File: `config/CorsConfig.java`. Replace the body of `addCorsMappings` with:

```java
registry.addMapping("/**")
        .allowedOriginPatterns("*")
        .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
        .allowedHeaders("*");
```

`OPTIONS` is used for browser preflight checks. These broad origins are for local classroom practice.

### 3.2 Complete the practice responses

File: `controllers/PracticeController.java`. Replace only the return statement in each matching method:

| Method | Required return statement |
| --- | --- |
| `getPractice` | `return ResponseEntity.ok("api initialised");` |
| `postPractice` | `return ResponseEntity.ok("youve posted: " + body);` |
| `putPractice` | `return ResponseEntity.ok("your update is : " + body);` |
| `patchPractice` | `return ResponseEntity.ok("you have updated the : " + body);` |
| `deletePractice` | `return ResponseEntity.ok("youve deleted : " + body);` |

Test `/api/practice` in Postman with all five methods. For writes, choose raw JSON and send `{"name":"demo"}`. Spaces and punctuation matter. Then test the frontend's Lesson 1 console; Postman alone doesn't check browser CORS.

## 4. Lesson 2: database access, passwords and JWT (20 minutes)

### 4.1 Filter products by category: L2-1

File: `services/ProductService.java`. Replace `selectProducts` with:

```java
private List<Product> selectProducts(Long categoryId) {
    if (categoryId == null) return products.findAll();
    return products.findByCategoryId(categoryId);
}
```

No category means all products. A category ID means use the repository's filtered query.

### 4.2 Put the category name in the DTO: L2-2

In `ProductService.toResponse`, replace `String categoryName = null;` with:

```java
String categoryName = category == null ? null : category.getName();
```

This means: if there is no category, use null; otherwise get its name. Keep the rest of the mapper.

### 4.3 Hash passwords: L2-3

File: `services/AuthService.java`. Replace `hashPassword` with:

```java
private String hashPassword(String rawPassword) {
    return passwordEncoder.encode(rawPassword);
}
```

BCrypt stores a salted hash instead of the original password.

### 4.4 Check passwords: L2-4

In the same file, replace `passwordMatches` with:

```java
private boolean passwordMatches(String rawPassword, String storedHash) {
    return passwordEncoder.matches(rawPassword, storedHash);
}
```

Do not encode again and compare strings: BCrypt deliberately creates different salted hashes.

### 4.5 Create the JWT: L2-5

File: `security/JwtService.java`. Replace `generateToken` with:

```java
public String generateToken(User user) {
    Date now = new Date();
    Date expiration = new Date(now.getTime() + expirationMs);
    return Jwts.builder()
            .subject(user.getEmail())
            .claim("id", user.getId())
            .claim("role", user.getRole().name())
            .issuedAt(now)
            .expiration(expiration)
            .signWith(signingKey, Jwts.SIG.HS256)
            .compact();
}
```

The signature detects tampering. Expiry limits token lifetime. The existing `readClaims` verifies both; keep it.

### 4.6 Authenticate the current request: L2-6

File: `security/JwtFilter.java`. Replace `authenticate` with:

```java
private void authenticate(User user) {
    var authority = new SimpleGrantedAuthority("ROLE_" + user.getRole().name());
    var authentication = new UsernamePasswordAuthenticationToken(
            user.getEmail(), null, List.of(authority));
    SecurityContextHolder.getContext().setAuthentication(authentication);
}
```

The last line tells Spring Security who made this request. The role comes from the stored user, not an untrusted request body.

Remove the unused `import com.impact.ecommerce.exceptions.LessonTodo;` from `ProductService.java`, `AuthService.java` and `JwtService.java` after their throws are gone.

### 4.7 Check Lesson 2 before moving on

Restart. In Postman:

1. `GET /api/products` and `GET /api/products?category=1` should return product JSON.
2. `POST /api/auth/login` with `{"email":"user@impact.md","password":"user123"}` should return a token.
3. `GET /api/test/protected`: 401 without a token; 200 with Postman Authorization > Bearer Token.
4. `GET /api/admin/test`: 403 with the USER token; 200 after logging in as `admin@impact.md` / `admin123`.
5. `POST /api/auth/register` with `{"email":"student@example.com","password":"password123"}` should return 201 and a token. Use a fresh email; a duplicate returns 409.

The default JWT key changes on restart. Log in again if an old token stops working.

## 5. Lesson 3: cache and API documentation (20 minutes)

### 5.1 Turn on Redis

Follow [the native/Docker Redis instructions](../database/README.md#lesson-3-redis-optional-for-earlier-lessons). Docker is not required.

Add or change these values in your local `application-local.properties`; keep the PostgreSQL settings:

```properties
spring.cache.type=redis
spring.data.redis.host=localhost
spring.data.redis.port=6379
```

`redis-cli ping` (or `memurai-cli ping` on Windows) must answer `PONG`. Restart the backend.

### 5.2 Cache product reads: L3-1

File: `services/ProductService.java`. Uncomment this annotation directly above `list`:

```java
@Cacheable(cacheNames = "products", key = "#categoryId != null ? #categoryId : 'all'")
```

Keep the method body. All products use key `products::all`; category 1 uses `products::1`. Separate keys prevent one category's result being returned for another.

### 5.3 Cache categories: L3-2

In the same file, uncomment directly above `categories`:

```java
@Cacheable(cacheNames = "categories", key = "'all'")
```

The category list uses `categories::all`.

### 5.4 Invalidate product caches after writes: L3-3

Uncomment this annotation above **each** method: `create`, `update` and `delete`:

```java
@CacheEvict(cacheNames = "products", allEntries = true)
@Transactional
```

`@Transactional` already exists; do not duplicate it. Keep each method body.

Why all entries? Changing a product can change the complete list and both its old/new category lists. Clearing one key is not enough.

`CacheConfig` already sets a **60-second TTL**. TTL means a cached value expires automatically. Eviction removes it sooner when we know data changed. Redis eviction is deferred until the transaction successfully commits.

### 5.5 Enable the clear button: L3-4

File: `services/CatalogCacheService.java`. Replace the placeholder annotation/comment and `clear` method with:

```java
@CacheEvict(cacheNames = {"products", "categories"}, allEntries = true)
public void clear() {
}
```

Remove its unused `LessonTodo` import. The empty body is intentional: Spring handles the annotation. The controller calls this separate service so Spring's cache interception runs.

This clears only catalog cache entries, not products in PostgreSQL. The endpoint is public for the existing localhost classroom frontend; it is not a general-purpose Redis administration route.

### 5.6 Add Swagger JWT authorization: L3-5

File: `config/OpenApiConfig.java`. Immediately after `Components components = new Components();`, insert:

```java
components.addSecuritySchemes("bearerAuth", new SecurityScheme()
        .type(SecurityScheme.Type.HTTP)
        .scheme("bearer")
        .bearerFormat("JWT"));
```

Keep the existing return statement. This describes how Swagger should send a token; `SecurityConfig` still decides actual access.

### 5.7 Finish the product description: L3-6

File: `controllers/CatalogController.java`. Replace the placeholder `@Operation` above `GET /products` with:

```java
@Operation(summary = "List products, optionally filtered by category")
```

Keep all other annotations. Read the prepared success/error responses together with the class: 200 means success, 400 bad input, 401 not authenticated, 403 insufficient permission, 404 missing resource, 409 conflict, 501 unfinished exercise, 503 Redis unavailable.

### 5.8 Demonstrate Lesson 3

1. Open `http://localhost:8080/swagger-ui/index.html`.
2. Execute login. Copy only the returned token, click **Authorize**, and paste it without the `Bearer ` prefix.
3. Try the protected route. Log in as ADMIN to test an ADMIN route.
4. Request `/api/products` twice, then run `redis-cli --scan --pattern 'products::*'` and `redis-cli TTL products::all`.
5. TTL should be 1-60 seconds; `-2` means the key is absent. Read again if it expired.
6. Request `/api/categories` and inspect `categories::all`.
7. Send `POST /api/cache/clear`. Inspect keys before another catalog GET: they should be gone. The frontend immediately reloads products, so its clear button may already have repopulated them.
8. As ADMIN, create/update/delete a product. Inspect keys before another GET to see invalidation.

Faster timing alone does not prove caching. Inspect keys/TTL and run the automated checks.

## 6. Match the solution's test settings and final checks (10 minutes)

### 6.1 Run all completion tests

Windows: `.\setup.cmd check`. Mac/Debian: `bash setup.sh check`.

This runs `mvn -Plesson-check test`. It does not require live PostgreSQL/Redis: tests use H2 and an in-memory cache. Use the real-service checks above too.

### 6.2 Make ordinary builds check completed work too

In the **top-level** `<properties>` section of `pom.xml`, replace:

```xml
<excludedGroups>lesson-complete</excludedGroups>
```

with:

```xml
<excludedGroups>lesson-starter</excludedGroups>
```

This matches `solution`: ordinary builds now include the completed exercises' tests. Do this after filling the answers, otherwise setup's build will correctly fail.

### 6.3 Add the solution's two extra Lesson 1 tests

File: `src/test/java/com/impact/ecommerce/Lesson1BackendApplicationTests.java`.

Paste the following methods **inside the existing class, before its final closing brace**. Keep the existing three tests. Required types are already imported or fully qualified below.

```java
    @Test
    void completedPracticeResponsesMatchLessonText() throws Exception {
        String body = "{\"name\":\"demo\"}";
        String[] methods = {"POST", "PUT", "PATCH", "DELETE"};
        String[] prefixes = {"youve posted: ", "your update is : ", "you have updated the : ", "youve deleted : "};
        for (int i = 0; i < methods.length; i++) {
            mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                    .request(org.springframework.http.HttpMethod.valueOf(methods[i]), "/api/practice")
                    .contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isOk()).andExpect(content().string(prefixes[i] + body));
        }
    }

    @Test
    void completedCorsAllowsEveryLessonMethod() throws Exception {
        for (String method : new String[]{"GET", "POST", "PUT", "PATCH", "DELETE"}) {
            mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                    .options("/api/practice").header("Origin", "http://localhost:5500")
                    .header("Access-Control-Request-Method", method))
                    .andExpect(status().isOk())
                    .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5500"))
                    .andExpect(header().string("Access-Control-Allow-Methods", org.hamcrest.Matchers.containsString(method)));
        }
    }
```

With these methods and every answer completed, the current project has **21 passing application tests**.

### 6.4 Confirm you reached the reference behavior

- [ ] Lesson 1: exact text for all five methods, and browser preflights work.
- [ ] Lesson 2: products come from PostgreSQL; passwords are hashed; USER cannot use ADMIN routes.
- [ ] Lesson 3: Redis keys/TTL work, writes evict caches, clear works, Swagger has Authorize.
- [ ] All completion tests pass.
- [ ] No unfinished `LessonTodo.required(...)` calls remain in the implemented service methods.
- [ ] No local credentials or frontend changes are staged.

The snippets produce the same executable answers and test configuration as `solution`. Comments saying TODO versus Answer and README wording do not affect behavior. To match the reference presentation, change completed TODO comments to explanations and state in README that your answers are completed. Keep the `LessonTodo` helper for future lessons.

## 7. Save your work

On your own feature branch:

```sh
git add .
git diff --cached
git commit -m "feat: complete lessons 1 to 3"
git push -u origin HEAD
```

Open a PR to your own `main`, review the complete diff, and merge when checks pass. Don't push to the teacher's repository or the frontend repository.

## Quick troubleshooting

| What you see | What to check |
| --- | --- |
| 501 response | A placeholder throw remains in a required method. |
| 401 after login | Check L2-6, token expiry, and whether you restarted since obtaining the token. |
| 403 for a USER on an ADMIN route | Correct behavior. Use the ADMIN account for ADMIN work. |
| Swagger has no Authorize button | Complete L3-5 and restart. |
| No Redis keys | Enable Redis locally, restart, complete caching annotations and make a catalog request. |
| Keys reappear after clearing | Another read repopulated the cache; the frontend reloads after clearing. |
| 503 during catalog/cache requests | Redis is enabled but unavailable. Start it or disable caching for earlier lessons. |
| PostgreSQL connection/password error | Start PostgreSQL and fix local connection settings. |
| Starter build passes but check fails | The starter excludes exercise tests; `check` includes them. |
