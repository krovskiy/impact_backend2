# Tema 4 — cerințe și rezolvare

Sursă: `3a23d4bf-hw_ro (1).pdf`. Cerințele materialului sunt: alegerea unui serviciu/controller cu code smell; o propoziție despre principiul SOLID încălcat; refactorizare fără schimbarea comportamentului; teste înainte și după; un PR către `main` cu diff recitit. Mai jos este soluția gata inclusă pe `main`.

## 1–2. Alegerea și explicația

**`ProductService` amesteca operațiile de catalog cu transformarea entităților în răspunsuri HTTP, încălcând Single Responsibility deoarece schimbările de business și schimbările formei DTO aveau motive diferite.**

## 3. Refactorizare: Extract Class

Înainte, metoda `ProductService.toResponse` citea categoria și construia `ProductResponse` cu toate câmpurile. După, această logică aparține clasei `ProductMapper`, injectată prin constructor. Metoda publică existentă `ProductService.toResponse` delegă spre mapper, păstrând contractul pentru apelanți.

```java
// Lesson 4 homework — ProductService
public ProductResponse toResponse(Product product) {
    return mapper.toResponse(product);
}
```

Implementarea completă este în `src/main/java/com/impact/ecommerce/services/ProductMapper.java`.

Păstrăm: aceleași endpoint-uri și coduri HTTP; aceleași câmpuri DTO; categoria `null`; aliasul JSON `category`; regulile ADMIN; prețurile `BigDecimal`; tranzacțiile și invalidarea cache-ului. Maparea are loc în tranzacția serviciului, unde categoria JPA poate fi încărcată.

## 4. Teste înainte și după

Înainte de refactorizare, `mvn test` pe soluțiile 1–3 (`3655e03`) a trecut: **21 teste, 0 eșecuri, 0 erori**. După refactorizare, comanda rămâne `mvn test`; suita include și `Lesson4Tests`. Testele existente verifică filtrarea, câmpurile DTO, autentificarea și invalidarea cache-ului, iar testele noi acoperă cazul fără categorie și `/api/auth/me`.

**Rezultat verificat:** `mvn test`: 26 teste, 0 failures, 0 errors.

## 5. Exemplu de descriere PR pentru elevi

**Titlu:** `refactor: extract product response mapping`

**Descriere:** `ProductService` combina operațiile de catalog cu maparea DTO. Am extras `ProductMapper` și am păstrat contractul public, câmpurile JSON, tranzacțiile și cache-ul. Am rulat `mvn test` înainte și după și am recitit diff-ul.

Pentru un exercițiu nou în repository-ul elevului: creează o ramură, fă propria refactorizare, rulează testele și deschide PR către propriul `main`. Soluția din acest repository este deja pe `main`; textul PDF-ului nu a declanșat automat publicarea unui PR.
