# Lecția 4 — Clean Code și SOLID: soluții incluse

Material: `3a23d4bf-lesson4_ro.pptx`, în special slide-urile 16–17 și 25–26.

- L4-1: `MeResponse(email, role)` este DTO-ul tipizat.
- `GET /api/auth/me` delegă spre `AuthService.me(email)`; serviciul caută utilizatorul.
- Endpoint-ul cere JWT valid și permite atât USER, cât și ADMIN. Nu expune parola/hash-ul.
- Tema: `ProductMapper` preia transformarea entitate → DTO din `ProductService`, păstrând câmpurile și comportamentul.
- `mvn test`: lecțiile 1–3 și testele noi pentru H2, conturi demo, `/me`, Swagger și mapare.

În Swagger: `POST /api/auth/login`, copiază `token`, apasă **Authorize**, introdu tokenul, apoi `GET /api/auth/me`.

Răspuns USER:

```json
{"email":"user@impact.md","role":"USER"}
```

[Ghid profesor](docs/LESSON4_TEACHER.md) · [Tema rezolvată](docs/LESSON4_HOMEWORK.md)
