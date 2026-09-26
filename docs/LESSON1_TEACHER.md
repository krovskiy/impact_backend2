> **Actualizare pentru main (lecțiile 1–4):** soluțiile sunt deja completate. Pornește cu `mvn spring-boot:run`, verifică prin `mvn test`. H2 și cache-ul local pornesc automat; nu instala PostgreSQL/Redis și nu schimba pe `solution`. [Instrucțiuni actuale](../README.md) · [Hartă soluții](LESSON_SOLUTIONS.md) · [Lecția 4](LESSON4_TEACHER.md).
>
> **Material istoric mai jos:** pașii vechi de instalare PostgreSQL/Redis, TODO-urile și comparațiile main/solution nu mai descriu configurarea curentă. Exemplele de predare se pot folosi pentru explicarea soluțiilor.

# Lecția 1: ghid pentru profesor și răspunsuri

Scop: cinci metode HTTP, corpul cererii și CORS. Plan de 20 de minute: 5 pentru exemplu, 10 pentru TODO-uri, 5 pentru verificare.

Pornește de la [lista elevului](../LESSON1_CHECKLIST.md). Proiectul cumulativ cere PostgreSQL; Redis poate rămâne dezactivat până la lecția 3.

## Răspunsuri

În `config/CorsConfig.java`:

```java
registry.addMapping("/**")
        .allowedOriginPatterns("*")
        .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
        .allowedHeaders("*");
```

Regula largă este pentru practica locală. Nu acordă drepturi de autentificare sau ADMIN.

În metodele corespunzătoare din `controllers/PracticeController.java`:

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

Textele API rămân în engleză deoarece sunt contractul verificat de teste și frontend.

## Demonstrație

Trimite cererile la `/api/practice` în Postman. Pentru scrieri folosește JSON brut `{"name":"demo"}` și `Content-Type: application/json`. Compară inclusiv spațiile. Apoi verifică consola lecției 1 din frontend.

Explică faptul că Postman nu verifică regulile CORS ale browserului. Ramura `solution` include teste pentru răspunsurile exacte și toate preflight-urile. Din lecția 3, elevii folosesc o ramură de lucru și un PR în propriul repository.
