# Lecția 2: recuperare rapidă și răspunsuri

Pregătește [PostgreSQL](../database/README.md) înainte de oră. Instalarea nativă este potrivită calculatoarelor cu puțină memorie. Java rămâne **21**.

| Minute | Activitate |
| --- | --- |
| 0–5 | Porniți aplicația, inspectați cele trei tabele și GET /api/products. |
| 5–10 | Urmăriți entity → repository → service → DTO → controller. L2-1 și L2-2. |
| 10–17 | Completați BCrypt L2-3/L2-4; explicați salt și protejarea parolelor. |
| 17–25 | Completați JWT L2-5 și contextul L2-6; explicați semnătura, expirarea și rolurile. |
| 25–35 | Verificați în Postman 401/403/200, apoi frontend-ul. |

Entitățile, SQL-ul, validarea, controllerele și regulile de acces sunt pregătite. Elevii modifică șase secțiuni. Înainte de completare, autentificarea rămâne blocată. Înregistrarea întoarce token pentru compatibilitatea frontend-ului și acordă doar USER. Cheia implicită se schimbă la repornire; autentificați-vă din nou.

## Răspunsuri

Înlocuiește codul provizoriu; nu lăsa un `throw` înainte de `return`.

**L2-1 — ProductService.selectProducts**, după cazul cu `categoryId == null`:

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

**L2-5 — JwtService.generateToken**, păstrând variabilele `now` și `expiration`:

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

**L2-6 — JwtFilter.authenticate**, după crearea autentificării:

```java
SecurityContextHolder.getContext().setAuthentication(authentication);
```

## Verificare și lecții viitoare

`mvn test` verifică infrastructura pregătită pe main. `mvn -Plesson-check test` include toate răspunsurile elevilor, inclusiv lecția 3. Testele folosesc H2, nu PostgreSQL-ul elevilor. Verificați separat aplicația reală. Pe solution, toate testele rulează implicit.

Pentru lecția următoare adaugă lista de verificare în README. Marchează testele de completare cu `@Tag("lesson-complete")` și păstrează comenzile setup/run/check. Folosește etichete L3-1, L4-1 etc. Main păstrează exercițiile; solution, răspunsurile.

SQL-ul se execută înaintea validării JPA la fiecare pornire. Orice SQL nou trebuie să poată fi rulat repetat și să păstreze datele. `CREATE TABLE IF NOT EXISTS` nu modifică automat coloanele existente.
