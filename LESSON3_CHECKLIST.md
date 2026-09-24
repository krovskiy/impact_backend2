# Lecția 3: Redis, Swagger și Git

Termină lecția 2, pornește PostgreSQL și [activează Redis](database/README.md#redis-pentru-lectia-3).

Caută `TODO Lesson 3` în `src/main/java/com/impact/ecommerce/`.

| Gata | TODO | Fișier | Ce completezi |
| --- | --- | --- | --- |
| [ ] | L3-1 | services/ProductService.java | Cache pentru produse, cu chei diferite pentru toate produsele și fiecare categorie. |
| [ ] | L3-2 | services/ProductService.java | Cache pentru categorii. |
| [ ] | L3-3 | services/ProductService.java | Invalidarea tuturor listelor de produse după create, update ȘI delete. |
| [ ] | L3-4 | services/CatalogCacheService.java | Activarea golirii ambelor cache-uri și eliminarea excepției TODO. |
| [ ] | L3-5 | config/OpenApiConfig.java | Schema JWT `bearerAuth`. |
| [ ] | L3-6 | controllers/CatalogController.java | Descrierea listei de produse și verificarea răspunsurilor documentate. |

## Demonstrează că funcționează

1. Rulează `.\setup.cmd check` sau `bash setup.sh check`. Testele automate nu cer Redis; trebuie să termini exercițiile incluse.
2. Pornește aplicația. Deschide **http://localhost:8080/swagger-ui/index.html** și **http://localhost:8080/v3/api-docs**.
3. În Swagger, autentifică-te cu `admin@impact.md` / `admin123`. Copiază tokenul, apasă **Authorize** și lipește-l fără prefixul `Bearer`. Testează `/api/admin/test`.
4. Cere `/api/products` de două ori. Inspectează cheile și TTL-ul folosind comenzile din ghidul bazei de date.
5. Cere `/api/categories` și verifică `categories::all`.
6. Trimite `POST /api/cache/clear`. Cheile dispar; datele din PostgreSQL rămân. Următoarea citire reface cache-ul.
7. Creează, modifică și șterge un produs ca ADMIN. După fiecare scriere reușită, cheile produselor trebuie invalidate.

TTL-ul este de 60 de secunde. Viteza singură nu demonstrează caching-ul. Frontend-ul recitește produsele după golire, deci poate recrea imediat cheile.

## Predă tema

În **repository-ul tău**:

```sh
git switch main
git pull --ff-only origin main
git switch -c feature/l3-redis-cache
# Completează TODO-urile, apoi:
git add .
git commit -m "feat: add Redis caching and Swagger"
git push -u origin feature/l3-redis-cache
```

Deschide un PR către propriul `main`. Citește toate diferențele, cere verificarea unui coleg și integrează după ce trec testele. Include capturi cu Swagger Authorize, cheile/TTL și golirea cache-ului. Răspunsurile de referință sunt pe `solution`.
