# Impact Backend

Lecțiile 1–4 și tema sunt rezolvate în cod. Comentariile indică lecția.

## Pornire

Ai nevoie de **JDK 21 și Maven**. În terminalul proiectului, pe Windows sau macOS:

```sh
mvn spring-boot:run
```

Deschide **http://localhost:8080/**. Swagger: **http://localhost:8080/swagger-ui/index.html**. Oprește cu **Ctrl+C**.

H2 și cache-ul local pornesc automat. Frontend-ul este inclus. Prima rulare descarcă dependențele Maven și necesită internet.

| Acțiune | Windows PowerShell | macOS / Linux |
| --- | --- | --- |
| Pornire | `.\setup.cmd run` | `bash setup.sh run` |
| Teste | `.\setup.cmd check` | `bash setup.sh check` |
| Alt port | `.\setup.cmd run 8081` | `bash setup.sh run 8081` |
| Instalare unelte, dacă lipsesc | `.\setup.cmd install` | `bash setup.sh install` |

`mvn test` rulează toate testele. În IntelliJ, setează Project SDK și Maven Runner JRE la 21. Verifică Java folosit de Maven cu `mvn -version`.

## Conturi demo

| Rol | Email | Parolă |
| --- | --- | --- |
| ADMIN | `admin@impact.md` | `admin123` |
| USER | `user@impact.md` | `user123` |

**Datele H2 se resetează la oprire.** La pornire sunt create 3 categorii și 6 produse. Autentifică-te din nou după restart.

## Redis — opțional

Redis funcționează cu H2, fără PostgreSQL. Instalare: `.\setup.cmd redis` pe Windows (Memurai) sau `bash setup.sh redis` pe macOS. Dacă ai deja Docker, poți folosi `docker compose -f database/compose.yaml up -d --wait`.

Cu Redis pornit:

```sh
mvn spring-boot:run "-Dspring-boot.run.arguments=--spring.cache.type=redis"
```

Fără Redis, folosește comanda normală de pornire. Cache-ul local nu are TTL; configurația Redis are TTL de 60 de secunde. Vechiul `application-local.properties` nu mai este încărcat.
