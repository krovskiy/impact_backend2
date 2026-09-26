# Lecția 2 — soluții incluse

- L2-1: filtrare după categorie în `ProductService`.
- L2-2: numele categoriei în DTO; maparea se află acum în `ProductMapper` (refactorizarea temei 4).
- L2-3 / L2-4: BCrypt pentru înregistrare și verificarea parolelor în `AuthService`.
- L2-5: token semnat cu email, id, rol și expirare în `JwtService`.
- L2-6: identitate autentificată în `JwtFilter`; `SecurityConfig` aplică limitele USER/ADMIN.
- JPA folosește H2; SQL-ul și conturile demonstrative sunt pregătite automat.

Verificare: `mvn test`. Testează autentificarea în frontend sau Swagger cu conturile din [README](README.md).
