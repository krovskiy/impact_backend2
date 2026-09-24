# Lesson 2: six TODOs

**First:** [prepare PostgreSQL](database/README.md), then start the backend.
Search your project for `TODO Lesson 2`. Java files are under `src/main/java/com/impact/ecommerce/`.

| Done | TODO | File | Your task |
| --- | --- | --- | --- |
| [ ] | L2-1 | services/ProductService.java | Filter products by category ID. |
| [ ] | L2-2 | services/ProductService.java | Put the category name in the response DTO. Handle no category. |
| [ ] | L2-3 | services/AuthService.java | Hash the password with BCrypt. |
| [ ] | L2-4 | services/AuthService.java | Check a password against its hash. |
| [ ] | L2-5 | security/JwtService.java | Create a signed JWT with email, ID, role and expiry. |
| [ ] | L2-6 | security/JwtFilter.java | Put the authenticated user in the security context. |

## Check your work

Windows: `.\setup.cmd check`  
Mac/Linux: `bash setup.sh check`

**Failures are expected until you finish.** These checks use a temporary in-memory database; PostgreSQL is needed to run the app.

Restart the backend after editing. Test in Postman:

1. `GET http://localhost:8080/api/products` shows seeded products.
2. `GET http://localhost:8080/api/products?category=1` filters them.
3. `POST http://localhost:8080/api/auth/register` with JSON `{"email":"student@example.com","password":"password123"}` returns **201** and a token.
4. `POST http://localhost:8080/api/auth/login` with that JSON returns a token.
5. `GET http://localhost:8080/api/test/protected`: **401** without a token, **200** with Postman Authorization → Bearer Token.
6. `GET http://localhost:8080/api/admin/test`: **403** with a USER token, **200** with an ADMIN token.

Seed accounts: `user@impact.md` / `user123`; `admin@impact.md` / `admin123`.
Login works after the auth TODOs are done. Open **http://localhost:8080/** to try the frontend.

In `psql`, run `SELECT email, role, password_hash FROM users;` — passwords must be hashes.
