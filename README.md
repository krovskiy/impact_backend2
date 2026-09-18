# Lesson 1 Backend Catch-up Starter

A deliberately **almost-complete** Spring Boot project for students who are behind on Lesson 1. It starts successfully, has the required package structure, and shows where to work. The remaining Lesson 1 work is marked with `TODO Lesson 1` comments.

## What you need to install

### 1) Java
Install **JDK 17**.

The lesson material uses Java 17, and this project is compiled for Java 17. Spring Boot 3 requires Java 17 or newer, so there is no honest way to make the same Spring Boot 3 project run on literally every historical Java version. The safest classroom setup is: **everyone uses JDK 17**.

Check:

```bash
java -version
javac -version
```

Both should show version 17.x (or a newer JDK capable of running Java 17 bytecode).

Recommended distributions: Eclipse Temurin 17 or Microsoft/OpenJDK 17.

### 2) Git
Install Git and verify:

```bash
git --version
```

### 3) Postman
Install Postman Desktop. Use it to test GET, POST, PUT, PATCH and DELETE requests before connecting the frontend.

### 4) IDE
Any Java IDE is fine. IntelliJ IDEA Community is the easiest classroom choice. VS Code also works with the Java Extension Pack.

### 5) Maven
You do **not** need to install Maven separately if your IDE has Maven support, but command-line Maven is useful.

Check:

```bash
mvn -version
```

The output should show Java 17 as the JVM Maven is using.

## Run the project

From the project folder:

```bash
mvn spring-boot:run
```

Then open/test:

```text
http://localhost:8080/api/practice
```

The GET endpoint already works and returns:

```text
api initialised
```

## What the student still has to do

Search the project for:

```text
TODO Lesson 1
```

The important files are:

```text
src/main/java/com/impact/ecommerce/config/CorsConfig.java
src/main/java/com/impact/ecommerce/controllers/PracticeController.java
```

The goal is to finish CORS and the 5 HTTP verbs without having to rebuild the entire project from zero.

## Postman examples

Base URL:

```text
http://localhost:8080/api/practice
```

For POST / PUT / PATCH / DELETE, choose `Body -> raw -> JSON` and send for example:

```json
{"name":"demo"}
```

## Frontend used for checking the homework

```text
https://github.com/Victoras23/impact_2_year_fe.git
```

Recommended classroom workflow from the provided resources: pull `main` at the start of a lesson so the frontend contains the resources for that lesson.

## Reference backend repository

```text
https://github.com/Victoras23/impact_2_year_be.git
```

The provided resources say students can use the `students_init` branch as the empty starting point. This ZIP is an easier catch-up starter because most Lesson 1 scaffolding already exists.

## Suggested Git workflow

```bash
git clone <YOUR_REPOSITORY_URL>
cd lesson1-backend

git checkout -b lesson-1
# finish the TODOs

git add .
git commit -m "feat: complete lesson 1 practice endpoints"
git push -u origin lesson-1
```

Useful commit message examples:

```text
chore: initialise Spring Boot lesson 1 project
feat: add layered package structure
feat: scaffold practice REST controller
feat: configure CORS for lesson frontend
feat: complete lesson 1 HTTP verb responses
docs: add lesson 1 setup and catch-up guide
```

## Troubleshooting

If `mvn spring-boot:run` says the Java version is wrong, run `java -version` and `mvn -version`. They should both point to JDK 17 (or newer).

If port 8080 is busy, either stop the other app or temporarily change `server.port` in `src/main/resources/application.properties`. Remember to update the frontend/Postman URL too.

If the browser frontend fails but Postman works, check `CorsConfig.java` first.

If GET works but the other 4 checks fail, finish the TODO strings in `PracticeController.java` exactly as written in `LESSON1_CHECKLIST.md`.

## Romanian quick note

Proiectul pornește deja. Caută `TODO Lesson 1`, completează CORS și răspunsurile pentru POST/PUT/PATCH/DELETE, testează în Postman, apoi verifică frontend-ul până ai 5/5.

## Русская памятка

Проект уже запускается. Найди `TODO Lesson 1`, закончи CORS и ответы POST/PUT/PATCH/DELETE, проверь их в Postman, затем подключи frontend и добейся результата 5/5.
