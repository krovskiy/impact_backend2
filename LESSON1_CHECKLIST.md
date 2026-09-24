# Lecția 1: lista de verificare

Proiectul este pregătit aproape complet. Codul Java este în `src/main/java/com/impact/ecommerce/`.

- [ ] În `config/CorsConfig.java`, permite originile browserului cu `allowedOriginPatterns("*")`.
- [ ] Permite metodele GET, POST, PUT, PATCH, DELETE și OPTIONS.
- [ ] În `controllers/PracticeController.java`, înlocuiește răspunsurile TODO cu textele de mai jos.
- [ ] Repornește backend-ul și testează toate cele cinci metode la `/api/practice` în Postman.
- [ ] Pentru scrieri, trimite JSON brut cu `Content-Type: application/json`.
- [ ] Deschide http://localhost:8080/ și folosește consola lecției 1. Adresa API este `http://localhost:8080/api/practice`.
- [ ] Verifică și browserul: Postman singur nu demonstrează că regulile CORS funcționează.
- [ ] Salvează modificările într-o ramură din repository-ul tău și deschide un PR.

Pentru corpul `{"name":"demo"}`, răspunsurile exacte sunt:

```text
GET    -> api initialised
POST   -> youve posted: {"name":"demo"}
PUT    -> your update is : {"name":"demo"}
PATCH  -> you have updated the : {"name":"demo"}
DELETE -> youve deleted : {"name":"demo"}
```

Nu traduce aceste texte: testele și frontend-ul le verifică exact.
