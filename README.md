# Impact Backend — lecțiile 1–4 rezolvate

`main` conține soluțiile complete din `solution`, lecția 4 și tema rezolvată. Comentariile `Lesson 1`, `Lesson 2 L2-*`, `Lesson 3 L3-*` și `Lesson 4` arată de unde provine codul.

## Pornire rapidă — Windows și macOS

Ai nevoie de **JDK 21** și **Maven**. Deschide terminalul în folderul cu `pom.xml`:

```sh
java -version
mvn -version
mvn spring-boot:run
```

După mesajul `Started`, deschide **http://localhost:8080/**. Swagger: **http://localhost:8080/swagger-ui/index.html**. Oprire: **Ctrl+C**.

**H2 rulează în Java; cache-ul rulează în memorie.** Nu trebuie instalate PostgreSQL, Redis/Memurai sau Docker. Pagina frontend este inclusă în repository; nu mai trebuie clonată separat. Maven descarcă dependențele la prima rulare, deci atunci ai nevoie de internet.

| Acțiune | Windows PowerShell | macOS / Linux |
| --- | --- | --- |
| Pornire | `.\setup.cmd run` | `bash setup.sh run` |
| Toate testele | `.\setup.cmd check` | `bash setup.sh check` |
| Alt port | `.\setup.cmd run 8081` | `bash setup.sh run 8081` |
| Instalare unelte, doar dacă lipsesc | `.\setup.cmd install` | `bash setup.sh install` |

Comanda **`mvn test` funcționează identic pe ambele sisteme**. În IntelliJ: Project SDK și Maven Runner JRE = 21, apoi Reload Maven. Dacă `mvn -version` arată alt Java, corectează `JAVA_HOME` și redeschide terminalul.

## Conturi și date demonstrative

| Rol | Email | Parolă |
| --- | --- | --- |
| ADMIN | `admin@impact.md` | `admin123` |
| USER | `user@impact.md` | `user123` |

La fiecare pornire sunt create 3 categorii și 6 produse. **Datele introduse în H2 se pierd când oprești aplicația.** Aceasta este alegerea pentru clasă, ca fiecare pornire să aibă aceeași bază curată. Tokenurile se regenerează: autentifică-te din nou după restart.

Vechiul `application-local.properties` nu mai este importat, iar variabilele vechi `DB_URL`, `DB_USER`, `DB_PASSWORD` nu mai sunt folosite. Nu trebuie să ștergi PostgreSQL de pe calculator. Elimină din configurația Run a IDE-ului eventualele suprascrieri explicite `SPRING_DATASOURCE_*` / `SPRING_CACHE_TYPE` dacă ai setat astfel de valori anterior.

## Lecții și soluții

- [Lecția 1 — HTTP și CORS](LESSON1_CHECKLIST.md)
- [Lecția 2 — JPA, catalog, BCrypt, JWT și roluri](LESSON2_CHECKLIST.md)
- [Lecția 3 — cache și Swagger](LESSON3_CHECKLIST.md)
- [Lecția 4 — Clean Code și SOLID](LESSON4_CHECKLIST.md)
- [Ghid profesor: lecția 4](docs/LESSON4_TEACHER.md)
- [Tema 4: cerințe și rezolvare explicată](docs/LESSON4_HOMEWORK.md)
- [Hartă completă: lecție → cod](docs/LESSON_SOLUTIONS.md)

Redis rămâne un exercițiu opțional: [instrucțiuni](database/README.md). Cache-ul local folosește aceleași adnotări, dar nu are TTL-ul de 60 de secunde al configurației Redis.

Pentru actualizare din propriul repository, salvează întâi lucrul local, apoi `git switch main` și `git pull --ff-only`. Nu este necesară trecerea pe `solution`.
