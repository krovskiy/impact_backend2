# Lecția 3 — soluții incluse

- L3-1 / L3-2: `@Cacheable` pentru produse pe categorie și lista de categorii.
- L3-3: `@CacheEvict` pe creare, actualizare și ștergere de produse.
- L3-4: `CatalogCacheService.clear()` șterge ambele cache-uri, fără să șteargă produsele.
- L3-5: schema Bearer JWT în `OpenApiConfig`.
- L3-6: descrierea endpoint-ului de produse în `CatalogController`.

Cache-ul local este activ automat. Swagger: http://localhost:8080/swagger-ui/index.html. Redis/Memurai este [opțional](database/README.md); numai configurația Redis are TTL 60 secunde. Testele `Lesson3Tests` verifică hit-uri, invalidare și documentarea API fără server Redis.

Rulează `mvn test`. [Pornire](README.md) · [Lecția 4](LESSON4_CHECKLIST.md)
