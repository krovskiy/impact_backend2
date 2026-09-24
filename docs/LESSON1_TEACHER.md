# Lesson 1: teacher guide and answers

Goal: five HTTP methods, request bodies and browser CORS. Allow 20 minutes: 5 for the request/response example, 10 to fill the TODOs, 5 to test.

Start with [the student checklist](../LESSON1_CHECKLIST.md). PostgreSQL is needed to run the current cumulative project; Redis is optional. Keep later lesson TODOs for their own class.

## Answers

In `config/CorsConfig.java`:

```java
registry.addMapping("/**")
        .allowedOriginPatterns("*")
        .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
        .allowedHeaders("*");
```

This broad CORS rule is for local classroom practice. It does not grant API authorization.

In `controllers/PracticeController.java`, use these return statements in the matching methods:

```java
// GET
return ResponseEntity.ok("api initialised");
// POST
return ResponseEntity.ok("youve posted: " + body);
// PUT
return ResponseEntity.ok("your update is : " + body);
// PATCH
return ResponseEntity.ok("you have updated the : " + body);
// DELETE
return ResponseEntity.ok("youve deleted : " + body);
```

## Demonstration

Send each request to `/api/practice` in Postman; for writes, use raw JSON `{"name":"demo"}` and `Content-Type: application/json`. Compare text exactly with the checklist. Then use the frontend's Lesson 1 API console. Explain that CORS affects browsers; a successful Postman request alone does not prove the CORS rule is correct.

The `solution` branch includes automated checks for all responses and browser preflight methods. From Lesson 3 onward, students save changes on feature branches and open a PR in their own repository.
