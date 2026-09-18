# Lesson 1 catch-up checklist

The project is intentionally **almost finished**. Complete these items yourself:

- [ ] In `config/CorsConfig.java`, allow browser requests using `allowedOriginPatterns("*")`.
- [ ] In `config/CorsConfig.java`, allow all lesson HTTP methods: GET, POST, PUT, PATCH, DELETE.
- [ ] In `controllers/PracticeController.java`, replace the TODO responses with the exact required strings.
- [ ] Run the backend and verify `GET /api/practice`.
- [ ] Test POST / PUT / PATCH / DELETE with a JSON body in Postman.
- [ ] Clone/open the lesson frontend and point its API console to `http://localhost:8080/api/practice`.
- [ ] Make sure all 5 frontend cards become green (5 / 5).
- [ ] Create your own GitHub repository, add it as `origin`, and commit your work on a new branch.

## Exact required responses

Given request body:

```json
{"name":"demo"}
```

Expected text:

```text
GET    -> api initialised
POST   -> youve posted: {"name":"demo"}
PUT    -> your update is : {"name":"demo"}
PATCH  -> you have updated the : {"name":"demo"}
DELETE -> youve deleted : {"name":"demo"}
```
