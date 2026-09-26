# Hartă: lecție → soluție

Toate căile Java sunt relative la `src/main/java/com/impact/ecommerce/`.

| Lecția | Fișiere și soluții |
| --- | --- |
| 1 — HTTP | `controllers/PracticeController.java`: toate metodele HTTP; `config/CorsConfig.java`: metodele permise; `Lesson1BackendApplication.java`: pornirea Spring. |
| 2 — date | `entities/`, `repositories/`, `dtos/product/`, `services/ProductService.java`: JPA, filtrare și CRUD; `database/*.sql`: H2 și date demo. |
| 2 — autentificare | `services/AuthService.java`, `security/JwtService.java`, `security/JwtFilter.java`, `config/SecurityConfig.java`, `dtos/auth/`: BCrypt, JWT și roluri. |
| 3 — cache | `services/ProductService.java`, `services/CatalogCacheService.java`, `config/CacheConfig.java`, `controllers/CacheController.java`: citire din cache și invalidare; local implicit, Redis opțional. |
| 3 — Swagger | `config/OpenApiConfig.java` și adnotările controller-elor: schema Bearer și descrieri endpoint-uri. |
| 4 — exemplul din slide-uri | `dtos/auth/MeResponse.java`, `AuthController.me`, `AuthService.me`, `SecurityConfig`: `/api/auth/me`, SRP și DTO tipizat. |
| 4 — tema | `services/ProductMapper.java`, `ProductService.toResponse`: Extract Class fără schimbarea comportamentului catalogului. |

Comentariile `Answer Lesson ...` existente au fost păstrate din ramura `solution`; codul nou este marcat `Lesson 4`. `mvn test` rulează verificările tuturor lecțiilor.

Frontend-ul din `src/main/resources/static/index.html` este copia paginii deja folosite de proiect, din `https://github.com/Victoras23/impact_2_year_fe`, commit `b4c14698ec0a0e06513816930eee12bf6b926ba8`. Nu este necesară clonarea acestui repository pentru pornire.

Nota: textul paginii pentru baza de date din lectia 2 a fost adaptat la H2.
