# Baza de date pentru clasă: H2

Rulează `mvn spring-boot:run`. H2 pornește în același proces Java, fără server, port SQL, cont PostgreSQL sau Docker. Maven include driverul H2 la rulare.

`create_tables.sql` creează tabelele; `insert_data.sql` adaugă conturile și catalogul. Scripturile sunt executate automat înainte de validarea JPA. Baza este în memorie și se resetează la oprire. Nu se migrează și nu se șterg datele din vechiul PostgreSQL.

## Lecția 3: Redis opțional

Cache-ul implicit este `simple`, în memoria aplicației. Pentru demonstrația Redis, pornește un Redis/Memurai existent sau instalează explicit cu `.\setup.cmd redis` (Windows) / `bash setup.sh redis` (macOS). Alternativ, dacă ai deja Docker: `docker compose -f database/compose.yaml up -d --wait`.

Activează explicit Redis, pe ambele sisteme:

```sh
mvn spring-boot:run "-Dspring-boot.run.arguments=--spring.cache.type=redis"
```

`application-local.properties` nu mai este încărcat. Pentru autentificarea Redis se pot folosi variabilele `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`. Dacă Redis nu rulează, repornește cu simplul `mvn spring-boot:run`, care folosește cache-ul local.

Referințe: [H2 în memorie](https://h2database.com/html/features.html#in_memory_databases), [Spring Boot cache providers](https://docs.spring.io/spring-boot/reference/io/caching.html).
