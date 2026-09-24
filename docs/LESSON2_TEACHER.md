# Lesson 2: quick catch-up

Prepare PostgreSQL before class using [database instructions](../database/README.md). Native installation is the main option for low-memory laptops; Docker is optional. Java stays at **21**.

Suggested 35-minute lesson:

| Minutes | Together |
| --- | --- |
| 0–5 | Run the SQL, inspect three tables and GET /api/products. |
| 5–10 | Trace entity → repository → service → DTO → controller. Complete L2-1 and L2-2. |
| 10–17 | Complete BCrypt L2-3 and L2-4; explain salts and why passwords never go in responses. |
| 17–25 | Complete token L2-5 and context L2-6; explain signature, expiry and roles. |
| 25–35 | Run completion checks, register/login in Postman, test 401/403/200, then use the frontend. |

Entities, repositories, SQL, validation, controllers, authorization and error responses are prepared. Students change six small sections. Unfinished authentication stays blocked. Register returns a token to match the existing frontend; students cannot request ADMIN during registration. Tokens expire after one hour; the default signing key changes on restart, so log in again.

Normal `mvn test` checks the prepared starter; `mvn -Plesson-check test` also checks the student answers. Tests use H2, not the classroom database. Native PostgreSQL smoke checks still matter. The frontend is fetched by the run launcher and is never edited or pushed by these changes.

## Answer key

Replace the indicated placeholder; do not leave a throw before your return.

**L2-1 — ProductService.selectProducts:**

```java
return products.findByCategoryId(categoryId);
```

**L2-2 — ProductService.toResponse:**

```java
String categoryName = category == null ? null : category.getName();
```

**L2-3 — AuthService.hashPassword:**

```java
return passwordEncoder.encode(rawPassword);
```

**L2-4 — AuthService.passwordMatches:**

```java
return passwordEncoder.matches(rawPassword, storedHash);
```

**L2-5 — JwtService.generateToken:**

```java
return Jwts.builder()
        .subject(user.getEmail())
        .claim("id", user.getId())
        .claim("role", user.getRole().name())
        .issuedAt(now)
        .expiration(expiration)
        .signWith(signingKey, Jwts.SIG.HS256)
        .compact();
```

**L2-6 — JwtFilter.authenticate:**

```java
SecurityContextHolder.getContext().setAuthentication(authentication);
```

After all six, the completion checks must pass. Use the seeded USER and ADMIN accounts from the student checklist to demonstrate role boundaries. Lesson 1 TODOs are retained for students still catching up.

## Adding future lessons

Keep the same setup/run/check commands. Add the next checklist and link it from README.
Mark student completion tests with `@Tag("lesson-complete")`; normal starter builds skip these, and `mvn -Plesson-check test` runs them all.
Keep exercise-specific labels such as L2-1 or L3-1 in the source. Main holds exercises; solution holds answers.
The shared SQL runs before JPA validation on each startup. New SQL must be safe to rerun and preserve existing student data. Existing table changes need explicit schema updates; CREATE TABLE IF NOT EXISTS does not upgrade columns.
