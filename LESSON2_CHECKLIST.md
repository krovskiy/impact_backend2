# Lecția 2: șase TODO-uri

**Mai întâi:** [pregătește PostgreSQL](database/README.md), apoi pornește backend-ul.
Caută `TODO Lesson 2`. Fișierele Java sunt în `src/main/java/com/impact/ecommerce/`.

| Gata | TODO | Fișier | Ce completezi |
| --- | --- | --- | --- |
| [ ] | L2-1 | services/ProductService.java | Filtrează produsele după ID-ul categoriei. |
| [ ] | L2-2 | services/ProductService.java | Pune numele categoriei în DTO; tratează și lipsa categoriei. |
| [ ] | L2-3 | services/AuthService.java | Calculează hash-ul parolei cu BCrypt. |
| [ ] | L2-4 | services/AuthService.java | Verifică parola folosind hash-ul salvat. |
| [ ] | L2-5 | security/JwtService.java | Creează JWT semnat cu email, ID, rol și expirare. |
| [ ] | L2-6 | security/JwtFilter.java | Pune autentificarea în contextul de securitate. |

## Verifică

Windows: `.\setup.cmd check`. Mac/Linux: `bash setup.sh check`.

**Erorile sunt normale până termini exercițiile incluse.** Comanda verifică și lecția 3; baza de test este în memorie. Pentru aplicația pornită normal ai nevoie de PostgreSQL.

Repornește backend-ul și testează în Postman:

1. `GET /api/products`: produsele demonstrative.
2. `GET /api/products?category=1`: produse filtrate.
3. `POST /api/auth/register` cu `{"email":"student@example.com","password":"password123"}`: **201** și token. Folosește un email nou.
4. `POST /api/auth/login` cu aceleași date: token.
5. `GET /api/test/protected`: **401** fără token; **200** cu Authorization > Bearer Token.
6. `GET /api/admin/test`: **403** cu token USER; **200** cu token ADMIN.

Adresa de bază: `http://localhost:8080`.
Conturi demonstrative: `user@impact.md` / `user123` și `admin@impact.md` / `admin123`.
Autentificarea funcționează după completarea TODO-urilor. După repornire, autentifică-te din nou.

În psql: `SELECT email, role, password_hash FROM users;`. Parolele trebuie să fie hash-uri, nu textul original.
