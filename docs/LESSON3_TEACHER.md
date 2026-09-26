> **Actualizare pentru main (lecțiile 1–4):** soluțiile sunt deja completate. Pornește cu `mvn spring-boot:run`, verifică prin `mvn test`. H2 și cache-ul local pornesc automat; nu instala PostgreSQL/Redis și nu schimba pe `solution`. [Instrucțiuni actuale](../README.md) · [Hartă soluții](LESSON_SOLUTIONS.md) · [Lecția 4](LESSON4_TEACHER.md).
>
> **Material istoric mai jos:** pașii vechi de instalare PostgreSQL/Redis, TODO-urile și comparațiile main/solution nu mai descriu configurarea curentă. Exemplele de predare se pot folosi pentru explicarea soluțiilor.

# Lecția 3: ghid pentru profesor și răspunsuri

Bazat pe prezentarea și tema furnizate: Redis, cache-aside, TTL de 60 de secunde, invalidare, Swagger/JWT și lucru prin ramuri/PR-uri. Regulile din materiale sunt exerciții pentru clasă, nu autorizații de modificare a protecției repository-ului.

## Plan de 40 de minute

| Minute | Activitate |
| --- | --- |
| 0–5 | Porniți PostgreSQL și Redis; terminați autentificarea din lecția 2. |
| 5–15 | Explicați hit/miss și cheile. L3-1/L3-2 și verificarea TTL. |
| 15–23 | L3-3/L3-4: modificați un produs și demonstrați invalidarea. |
| 23–30 | L3-5/L3-6: Swagger Authorize și 401/403/200. |
| 30–40 | Teste, ramură de lucru, commit, push și verificarea unui PR. |

Dependențele, serializarea JSON, TTL-ul și majoritatea adnotărilor Swagger sunt pregătite. `ProductService.categories()` îndeplinește rolul serviciului separat de categorii din prezentare. [Configurare Redis](../database/README.md#redis-pentru-lectia-3).

## Răspunsuri

**L3-1**, deasupra `ProductService.list`:

```java
@Cacheable(cacheNames = "products", key = "#categoryId != null ? #categoryId : 'all'")
```

**L3-2**, deasupra `ProductService.categories`:

```java
@Cacheable(cacheNames = "categories", key = "'all'")
```

**L3-3**, deasupra fiecărei metode `create`, `update`, `delete`:

```java
@CacheEvict(cacheNames = "products", allEntries = true)
```

Păstrează `@Transactional`. Managerul Redis aplică invalidarea după commit. Trebuie eliminate toate variantele filtrate, deoarece produsul își poate schimba categoria.

**L3-4**, în `CatalogCacheService`:

```java
@CacheEvict(cacheNames = {"products", "categories"}, allEntries = true)
public void clear() { }
```

**L3-5**, după `Components components = new Components();`:

```java
components.addSecuritySchemes("bearerAuth", new SecurityScheme()
        .type(SecurityScheme.Type.HTTP)
        .scheme("bearer")
        .bearerFormat("JWT"));
```

**L3-6**, deasupra rutei GET pentru produse:

```java
@Operation(summary = "List products, optionally filtered by category")
```

Descrierea rămâne exactă pentru testul de completare. Recitiți adnotările `@Tag`, `@ApiResponse` și `@SecurityRequirement`. O listă fără rezultate este 200 cu `[]`, nu 404. Login/register sunt publice.

## Verificări și explicații

Urmați [lista elevului](../LESSON3_CHECKLIST.md). Testele verifică hit-uri, chei separate, cele trei invalidări, golirea manuală, Swagger, serializarea și configurarea TTL. Pentru comportamentul cache folosesc memorie și verifică apelurile repository-ului; verificați și serverul Redis real.

Cache-ul conține numai DTO-uri publice, nu entități JPA, parole sau tokenuri. Cheile sunt `products::all`, `products::<id>` și `categories::all`. Goliți cache-ul când schimbați ramura folosind aceeași instanță Redis.

Frontend-ul trimite golirea fără token; ruta este publică în această aplicație locală și golește numai cele două cache-uri. Nu execută FLUSHALL și nu șterge datele PostgreSQL. Pentru publicarea aplicației în afara calculatorului, restricționați ruta și adaptați frontend-ul.

Cu caching dezactivat, golirea completată nu are efect. Redis activat dar inaccesibil produce 503. TTL limitează datele învechite, dar nu oferă consistență distribuită strictă: citirile concurente cu scrierile pot reintroduce temporar o valoare veche.

## Tema

Verifică ramura de lucru, PR-ul și recitirea întregului diff. Cere dovezi ale cheilor, TTL-ului și golirii, nu numai măsurarea timpului în frontend. Răspunsurile sunt pe solution; main păstrează TODO-urile. Lecțiile viitoare folosesc aceeași etichetă `lesson-complete` și aceeași comandă de verificare.
