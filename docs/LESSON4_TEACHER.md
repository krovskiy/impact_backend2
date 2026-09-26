# Lecția 4 — ghid profesor și soluție

## Pregătire (5 minute)

Toți folosesc `main`, JDK 21 și Maven. `mvn test`, apoi `mvn spring-boot:run`. Deschide http://localhost:8080/ și Swagger. H2 și cache-ul local pornesc automat; nu configura PostgreSQL sau Redis.

## Exemplul din prezentare (10 minute)

Slide-urile 16–17 prezintă mutarea logicii din controller într-un serviciu și folosirea `MeResponse`. În versiunea veche a acestui repository **nu exista `/api/auth/me`**, deci aici adăugăm endpoint-ul cu forma finală din slide-uri: `email` și `role` singular. Nu pretindem că vechiul răspuns `roles` exista în acest cod.

Citește în ordine: `dtos/auth/MeResponse.java`, `AuthController.me`, `AuthService.me`, regula din `SecurityConfig`. Controller-ul gestionează cererea HTTP; serviciul caută contul; DTO-ul definește datele publice. Identitatea vine din JWT verificat, nu dintr-un email trimis separat de client.

## SOLID în cod (10 minute)

| Principiu | Exemplu / explicație |
| --- | --- |
| S — Single Responsibility | `ProductMapper` mapează, `ProductService` coordonează operațiile de catalog. |
| O — Open/Closed | Cache-ul poate folosi implementarea locală sau Redis prin configurare, fără schimbarea operațiilor din serviciu. Exemplul cu discount din slide-ul 19 pregătește Strategy pentru lecția 5. |
| L — Liskov Substitution | Implementările respectă contractele. Pentru repository-uri/mock-uri trebuie păstrate semnificația datelor și rezultatele așteptate; nu adăugăm o subclasă artificială de utilizator. |
| I — Interface Segregation | Discută interfețe mici pentru necesități concrete; proiectul folosește repository-uri Spring Data și nu adaugă interfețe uriașe proprii. |
| D — Dependency Inversion | Serviciile primesc prin constructor abstracțiile `ProductRepository`, `CategoryRepository`, `UserRepository`, `PasswordEncoder`. |

## Tema rezolvată (15 minute)

Deschide [rezolvarea temei](LESSON4_HOMEWORK.md). Compară `ProductService` din commit-ul `3655e03` cu varianta curentă și `ProductMapper`. Arată că adnotările de cache și tranzacțiile au rămas pe serviciu, iar răspunsul frontend include în continuare `categoryName` și aliasul `category`.

Rulează `mvn test`. Suita existentă avea 21 de teste, nu cele 15 menționate în prezentare; folosim numărul real din proiect. Testele noi verifică și pornirea implicită cu date demonstrative, fără profilul `test`.

Elevii pot explica soluția gata scrisă înainte să încerce o refactorizare proprie. [Harta lecțiilor](LESSON_SOLUTIONS.md).
