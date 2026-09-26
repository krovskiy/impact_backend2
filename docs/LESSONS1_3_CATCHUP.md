> **Actualizare pentru main (lecțiile 1–4):** soluțiile sunt deja completate. Pornește cu `mvn spring-boot:run`, verifică prin `mvn test`. H2 și cache-ul local pornesc automat; nu instala PostgreSQL/Redis și nu schimba pe `solution`. [Instrucțiuni actuale](../README.md) · [Hartă soluții](LESSON_SOLUTIONS.md) · [Lecția 4](LESSON4_TEACHER.md).
>
> **Material istoric mai jos:** pașii vechi de instalare PostgreSQL/Redis, TODO-urile și comparațiile main/solution nu mai descriu configurarea curentă. Exemplele de predare se pot folosi pentru explicarea soluțiilor.

# Lecțiile 1–3: de la exerciții la soluție

Ghid pentru recuperarea rapidă la clasă. Mai întâi înțelegem structura, apoi modificăm codul în ordine. Versiunea aceasta corespunde proiectului până la lecția 3; lecțiile următoare pot adăuga alte fișiere.

Pornește din **main**. Pe **solution**, răspunsurile sunt deja completate. Rezervă aproximativ **60–75 de minute după instalarea instrumentelor și a bazelor de date**.

## 1. Înțelege proiectul înainte să modifici cod

### Ce construim?

**Frontend-ul** este pagina văzută în browser. **Backend-ul** este programul Java care primește cereri de la pagină. **PostgreSQL** păstrează datele permanent. **Redis** păstrează temporar copii ale răspunsurilor publice pentru citiri mai rapide.

Un **endpoint** este o adresă și o metodă HTTP. `GET /api/products` citește produsele; `POST /api/products` creează unul. O **cerere** merge către backend, un **răspuns** revine către client. Datele sunt frecvent JSON: `{"name":"Book","price":10}`.

### Drumul unei cereri

```text
Browser / Postman / Swagger
           |
           v
Filtru JWT: verifică tokenul trimis și identifică utilizatorul
           |
           v
Controller: alege metoda Java pentru adresa cerută
           |
           v
Service: aplică regulile și pregătește răspunsul
           |
           +---- Redis: întoarce copia salvată dacă există
           |
           v
Repository: citește/scrie rânduri în PostgreSQL
           |
           v
PostgreSQL

Răspunsul revine prin service și controller.
```

O **clasă** grupează date și comportament. O **metodă** este o acțiune dintr-o clasă. Un **pachet** grupează fișiere Java înrudite.

Spring creează și conectează obiectele. De exemplu, constructorul ProductService cere repository-urile, iar Spring le furnizează. Nu creăm manual un serviciu nou pentru fiecare cerere.

### Fișierele din rădăcină și instrumentele

| Fișier / folder | Rol |
| --- | --- |
| `pom.xml` | Rețeta Maven: Java 21, biblioteci, resurse incluse în aplicație și setări de test. |
| `setup.cmd` | Punctul de pornire Windows: instalare, run, redis, db, check. |
| `setup.sh` | Punctul de pornire Mac/Linux; alege scriptul platformei. |
| `scripts/setup-windows.ps1` | Instalează instrumentele și Memurai, actualizează frontend-ul, construiește și pornește aplicația. |
| `scripts/setup-macos.sh` | Apelează funcțiile comune pentru macOS. |
| `scripts/setup-debian.sh` | Apelează funcțiile comune pentru Debian. |
| `scripts/setup-common.sh` | Instalare Java/Maven/Redis, actualizare frontend, pornire și teste pe Mac/Linux. |
| `scripts/CheckPom.java` | Verifică XML-ul Maven și repară, când este sigur, greșeala cunoscută cu dependențe după finalul documentului. |
| `scripts/tests/test_setup.py` | Verifică scripturile folosind repository-uri Git temporare și instalări simulate. |
| `.gitignore` | Exclude fișiere locale, parole, frontend și rezultate generate. Fișierele deja urmărite rămân urmărite. |
| `.gitattributes` | Normalizează terminatorii de linie pentru Windows și scripturile shell. |
| `README.md` | Pașii scurți de pornire și legăturile către lecții. |
| `LESSON1_CHECKLIST.md`, `LESSON2_CHECKLIST.md`, `LESSON3_CHECKLIST.md` | Exercițiile și verificările elevilor. |
| `docs/LESSON1_TEACHER.md`, `docs/LESSON2_TEACHER.md`, `docs/LESSON3_TEACHER.md` | Planurile individuale și răspunsurile profesorului. |
| `docs/LESSONS1_3_CATCHUP.md` | Acest ghid combinat. |
| `frontend/` | Repository separat. Java servește `index.html`. Nu modifica sursele sau remote-ul lui. |
| `target/` | Clase compilate, JAR și rapoarte de test generate de Maven. Nu le edita. |
| `.git/` | Istoricul și ramurile Git. Nu modifica manual conținutul. |

### Baza de date și setările

| Fișier | Rol |
| --- | --- |
| `database/create_database.sql` | Creează baza `e-commerce` dacă lipsește; se execută cu psql. |
| `database/create_tables.sql` | Creează tabelele lipsă users, categories și products; nu actualizează automat coloane existente. |
| `database/insert_data.sql` | Adaugă date și conturi demonstrative fără resetarea înregistrărilor existente. |
| `database/compose.yaml` | PostgreSQL și Redis opționale în Docker. |
| `database/README.md` | Instrucțiuni pentru instalarea nativă sau Docker. |
| `database/application-local.properties.example` | Model pentru setările locale. |
| `application-local.properties` | Parolele locale și activarea Redis; ignorat de Git. Numele trebuie să fie exact acesta, nu .settings. |
| `src/main/resources/application.properties` | Setări comune: porturi, SQL, JWT și Redis. Inițializarea SQL are loc înainte de validarea JPA. |
| `src/test/resources/application-test.properties` | Baza H2 izolată pentru teste; nu modifică PostgreSQL-ul elevului. |

### Fiecare fișier Java și scopul lui

Toate căile de mai jos pornesc din `src/main/java/com/impact/ecommerce/`.

| Fișier | Rol |
| --- | --- |
| `Lesson1BackendApplication.java` | Pornește Spring Boot. Numele vechi nu limitează aplicația la lecția 1. |
| `config/CorsConfig.java` | Decide ce origini, metode și antete ale browserului sunt permise. Nu autentifică utilizatorul. |
| `config/SecurityConfig.java` | Decide ce rute sunt publice, autentificate sau ADMIN; configurează BCrypt și filtrul JWT. |
| `config/CacheConfig.java` | Activează caching-ul și configurează JSON Redis, TTL de 60 secunde și invalidarea după tranzacție. |
| `config/OpenApiConfig.java` | Titlul API și schema JWT folosită de butonul Authorize. |
| `controllers/PracticeController.java` | Cele cinci exerciții HTTP din lecția 1. |
| `controllers/AuthController.java` | Rutele register/login; validează datele și apelează AuthService. |
| `controllers/CatalogController.java` | Citirea produselor/categoriilor și scrierile ADMIN; documentația Swagger. |
| `controllers/TestController.java` | Rute mici pentru verificarea autentificării și rolului ADMIN. |
| `controllers/CacheController.java` | Ruta POST /api/cache/clear; cere golirea cache-urilor catalogului. |
| `services/AuthService.java` | Reguli de înregistrare, email duplicat, parole și răspunsuri de autentificare. |
| `services/ProductService.java` | Listează, filtrează, transformă, creează, modifică și șterge produse; listează și categoriile. |
| `services/CatalogCacheService.java` | Golește cache-urile produselor și categoriilor prin adnotările Spring. |
| `repositories/UserRepository.java` | Caută utilizatori după email și verifică dacă emailul există. |
| `repositories/ProductRepository.java` | Acces la produse și interogări după categorie sau nume. |
| `repositories/CategoryRepository.java` | Acces la categorii. Spring implementează aceste interfețe. |
| `entities/User.java` | Reprezintă rândul utilizatorului: ID, email, hash, rol, data creării. |
| `entities/Role.java` | Rolurile permise: USER și ADMIN. |
| `entities/Product.java` | Reprezintă produsul și relația opțională cu categoria; prețul folosește BigDecimal. |
| `entities/Category.java` | Reprezintă categoria: ID și nume. |
| `dtos/auth/RegisterRequest.java` | Câmpurile și validările înregistrării; nu acceptă alegerea rolului ADMIN. |
| `dtos/auth/LoginRequest.java` | Email/parolă și validări pentru login. |
| `dtos/auth/AuthResponse.java` | Token, ID, email și rol; fără hash-ul parolei. |
| `dtos/product/CreateProductRequest.java` | Date validate pentru crearea/modificarea produsului. |
| `dtos/product/ProductResponse.java` | JSON public al produsului; include aliasul category cerut de frontend. |
| `dtos/product/CategoryResponse.java` | ID/nume public al categoriei. |
| `security/JwtService.java` | Semnează tokenuri și verifică semnătura/expirarea. JWT semnat nu înseamnă criptat. |
| `security/JwtFilter.java` | Citește Authorization: Bearer, validează tokenul și identifică utilizatorul și rolul curent. |
| `exceptions/ApiExceptionHandler.java` | Transformă erorile cunoscute în JSON și coduri HTTP clare. |
| `exceptions/LessonTodo.java` | Întoarce 501 pentru exercițiile neterminate; elimini apelul când completezi exercițiul. |
| `package-info.java` | Comentarii despre pachete, fără cod executabil. Unele descriu încă structura inițială. |

O **entitate** reprezintă datele din bază. Un **DTO** precizează ce date pot intra sau ieși prin API. DTO-urile împiedică expunerea accidentală a detaliilor bazei și a hash-urilor parolelor.

### Testele

În `src/test/java/com/impact/ecommerce/`:

| Fișier | Verifică |
| --- | --- |
| `Lesson1BackendApplicationTests.java` | Servirea frontend-ului, ruta practice și protecția fișierelor private; solution adaugă răspunsurile exacte și CORS. |
| `Lesson2Tests.java` | Validare, parole, înregistrare, JWT și permisiuni. |
| `Lesson3Tests.java` | Swagger, serializare/TTL Redis, hit-uri și invalidare. Comportamentul cache este testat în memorie; verificăm separat Redis real. |

### Notații întâlnite în cod

| Notație | Înțeles |
| --- | --- |
| `@RestController` | Clasa primește cereri HTTP. |
| `@GetMapping` / `@PostMapping` | Metoda Java răspunde unei adrese și unei metode HTTP. |
| `@Service` | Obiect gestionat de Spring care conține regulile aplicației. |
| `@Entity` | Clasa corespunde unui tabel. |
| `@Valid` | Verifică regulile datelor înaintea executării controllerului. |
| `@Transactional` | Grupează operațiile: commit la succes sau rollback la eroare. |
| `@Cacheable` | La hit întoarce copia din cache; la miss execută metoda și salvează rezultatul. |
| `@CacheEvict` | Elimină valori din cache după un apel reușit. |
| `@Operation` / `@ApiResponse` | Descrie ruta și răspunsurile în Swagger. |
| `return` | Încheie metoda și întoarce rezultatul. |
| `throw` | Oprește execuția normală cu o eroare. |
| `null` | Valoare absentă. |

## 2. Pregătire înainte de oră

1. În copia ta de main creează o ramură de lucru: `git switch -c feature/recuperare-1-3`.
2. Rulează setup o singură dată: `setup.cmd` sau `bash setup.sh`.
3. Urmează [pregătirea PostgreSQL](../database/README.md). Creează e-commerce și salvează parola local.
4. Inițial folosește `spring.cache.type=none` în `application-local.properties`.
5. Pornește: `.\setup.cmd run` sau `bash setup.sh run`. Deschide http://localhost:8080/.
6. Oprește cu Ctrl+C și repornește după fiecare grup de modificări. Reîncărcarea automată Java nu este configurată.

Tabelele/datele demonstrative sunt pregătite la pornire. GET products funcționează înaintea completării tuturor exercițiilor. Autentificarea rămâne blocată până termini TODO-urile corespunzătoare.

## 3. Lecția 1: cereri, răspunsuri și CORS

Căile Java scurte pornesc din `src/main/java/com/impact/ecommerce/`.
Înlocuiește codul în clasa existentă. **Nu adăuga o a doua metodă cu același nume.** Păstrează importurile, mapping-urile și adnotările pregătite.

### 3.1. Permite cererile browserului

În `config/CorsConfig.java` înlocuiește corpul metodei `addCorsMappings`:

```java
registry.addMapping("/**")
        .allowedOriginPatterns("*")
        .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
        .allowedHeaders("*");
```

OPTIONS este folosit pentru verificările preflight. Originile largi sunt pentru practica locală.

### 3.2. Completează răspunsurile practice

În `controllers/PracticeController.java` înlocuiește numai return-ul metodei corespunzătoare:

| Metodă | Return |
| --- | --- |
| `getPractice` | `return ResponseEntity.ok("api initialised");` |
| `postPractice` | `return ResponseEntity.ok("youve posted: " + body);` |
| `putPractice` | `return ResponseEntity.ok("your update is : " + body);` |
| `patchPractice` | `return ResponseEntity.ok("you have updated the : " + body);` |
| `deletePractice` | `return ResponseEntity.ok("youve deleted : " + body);` |

Textele sunt intenționat în engleză: testele și frontend-ul verifică inclusiv spațiile. În Postman testează toate metodele pe /api/practice, cu JSON brut `{"name":"demo"}` pentru scrieri. Apoi testează browserul; Postman nu verifică CORS.

## 4. Lecția 2: bază de date, parole și JWT

### 4.1. Filtrarea produselor: L2-1

În `services/ProductService.java` înlocuiește metoda `selectProducts`:

```java
private List<Product> selectProducts(Long categoryId) {
    if (categoryId == null) return products.findAll();
    return products.findByCategoryId(categoryId);
}
```

Fără categorie întoarcem toate produsele; cu ID folosim interogarea filtrată.

### 4.2. Numele categoriei în DTO: L2-2

În `ProductService.toResponse` înlocuiește `String categoryName = null;`:

```java
String categoryName = category == null ? null : category.getName();
```

Dacă lipsește categoria folosim null; altfel luăm numele. Păstrează restul mapării.

### 4.3. Hash-ul parolei: L2-3

În `services/AuthService.java` înlocuiește `hashPassword`:

```java
private String hashPassword(String rawPassword) {
    return passwordEncoder.encode(rawPassword);
}
```

BCrypt salvează un hash cu salt, nu parola inițială.

### 4.4. Verificarea parolei: L2-4

În același fișier înlocuiește `passwordMatches`:

```java
private boolean passwordMatches(String rawPassword, String storedHash) {
    return passwordEncoder.matches(rawPassword, storedHash);
}
```

Nu calcula un hash nou pentru comparație directă: salt-ul produce intenționat hash-uri diferite.

### 4.5. Crearea tokenului: L2-5

În `security/JwtService.java` înlocuiește `generateToken`:

```java
public String generateToken(User user) {
    Date now = new Date();
    Date expiration = new Date(now.getTime() + expirationMs);
    return Jwts.builder()
            .subject(user.getEmail())
            .claim("id", user.getId())
            .claim("role", user.getRole().name())
            .issuedAt(now)
            .expiration(expiration)
            .signWith(signingKey, Jwts.SIG.HS256)
            .compact();
}
```

Semnătura detectează modificările; expirarea limitează durata tokenului. Păstrează `readClaims`, care le verifică. Nu pune parole în JWT.

### 4.6. Autentificarea cererii: L2-6

În `security/JwtFilter.java` înlocuiește `authenticate`:

```java
private void authenticate(User user) {
    var authority = new SimpleGrantedAuthority("ROLE_" + user.getRole().name());
    var authentication = new UsernamePasswordAuthenticationToken(
            user.getEmail(), null, List.of(authority));
    SecurityContextHolder.getContext().setAuthentication(authentication);
}
```

Ultima linie spune Spring Security cine a trimis cererea. Rolul provine din utilizatorul salvat.
Elimină importul nefolosit `import com.impact.ecommerce.exceptions.LessonTodo;` din ProductService, AuthService și JwtService după eliminarea excepțiilor provizorii.

### 4.7. Verifică înainte să continui

Repornește și testează în Postman:

1. GET /api/products și GET /api/products?category=1 întorc JSON.
2. POST /api/auth/login cu `{"email":"user@impact.md","password":"user123"}` întoarce token.
3. GET /api/test/protected: 401 fără token, 200 cu Authorization > Bearer Token.
4. GET /api/admin/test: 403 pentru USER; 200 cu token de la `admin@impact.md` / `admin123`.
5. POST /api/auth/register cu `{"email":"student@example.com","password":"password123"}`: 201 și token. Emailul trebuie să fie nou; duplicatul produce 409.

După repornire autentifică-te din nou: cheia JWT implicită se schimbă.

## 5. Lecția 3: Redis și documentația API

### 5.1. Pornește Redis, fără Docker dacă preferi

Windows: `.\setup.cmd redis`. Acceptă solicitarea de administrator.
Mac/Debian: `bash setup.sh redis`.

Dacă un container Redis ocupă portul și vrei Memurai, oprește-l explicit înainte:

```sh
docker compose -f database/compose.yaml stop redis
```

Păstrează setările PostgreSQL și adaugă în fișierul local:

```properties
spring.cache.type=redis
spring.data.redis.host=localhost
spring.data.redis.port=6379
```

Verificare Windows:

```powershell
& "C:\Program Files\Memurai\memurai-cli.exe" ping
```

Mac/Linux: `redis-cli ping`. Trebuie să primești **PONG**.
Dacă terminalul nu găsește comanda, verifică instalarea/PATH sau folosește calea completă.

Alternativ, Docker include propriul redis-cli; nu îl instala separat pe Windows:

```sh
docker compose -f database/compose.yaml --profile lesson3 up -d --wait redis
docker compose -f database/compose.yaml exec -T redis redis-cli ping
```

Docker trebuie să fie pornit. Dacă memoria nu ajunge, folosește instalarea nativă.
[Detalii de configurare](../database/README.md#redis-pentru-lectia-3). Repornește backend-ul după activarea Redis.

### 5.2. Cache pentru produse: L3-1

În `services/ProductService.java` decomentează deasupra `list`:

```java
@Cacheable(cacheNames = "products", key = "#categoryId != null ? #categoryId : 'all'")
```

Păstrează metoda. Lista completă folosește products::all; categoria 1 folosește products::1. Cheile diferite împiedică amestecarea rezultatelor.

### 5.3. Cache pentru categorii: L3-2

Decomentează deasupra `categories`:

```java
@Cacheable(cacheNames = "categories", key = "'all'")
```

Cheia este categories::all.

### 5.4. Invalidare după scriere: L3-3

Decomentează adnotarea pentru fiecare metodă: **create, update și delete**:

```java
@CacheEvict(cacheNames = "products", allEntries = true)
@Transactional
```

@Transactional există deja; nu îl dubla. Nu modifica metodele. O schimbare poate afecta lista completă și listele categoriilor vechi/noi, deci golim toate intrările produselor.

CacheConfig setează deja TTL la **60 de secunde**. TTL elimină automat copia după expirare; invalidarea o elimină imediat când știm că s-au schimbat datele. Managerul Redis invalidează după commit-ul reușit.

### 5.5. Butonul de golire: L3-4

În `services/CatalogCacheService.java` înlocuiește comentariul/adnotarea și metoda clear:

```java
@CacheEvict(cacheNames = {"products", "categories"}, allEntries = true)
public void clear() {
}
```

Elimină importul LessonTodo. Corpul gol este intenționat: Spring execută adnotarea. Controllerul apelează un serviciu separat, astfel încât interceptarea cache să funcționeze.

Nu se șterg produse din PostgreSQL. Ruta este publică pentru frontend-ul local al clasei, nu pentru administrarea generală Redis.

### 5.6. Autorizare JWT în Swagger: L3-5

În `config/OpenApiConfig.java`, imediat după `Components components = new Components();`:

```java
components.addSecuritySchemes("bearerAuth", new SecurityScheme()
        .type(SecurityScheme.Type.HTTP)
        .scheme("bearer")
        .bearerFormat("JWT"));
```

Păstrează return-ul. Aceasta descrie cum trimite Swagger tokenul; SecurityConfig decide accesul real.

### 5.7. Descrierea produselor: L3-6

În `controllers/CatalogController.java` înlocuiește @Operation provizoriu de la GET /products:

```java
@Operation(summary = "List products, optionally filtered by category")
```

Păstrează descrierea exactă pentru testul de completare. Celelalte adnotări sunt pregătite.
200 = succes; 400 = date invalide; 401 = neautentificat; 403 = permisiune insuficientă; 404 = resursă absentă; 409 = conflict; 501 = exercițiu neterminat; 503 = Redis indisponibil.

### 5.8. Demonstrație cu servicii reale

1. Deschide http://localhost:8080/swagger-ui/index.html.
2. Execută login, copiază tokenul și folosește **Authorize**, fără prefixul Bearer.
3. Testează ruta protejată și ruta ADMIN cu utilizatorul corespunzător.
4. Cere /api/products de două ori; inspectează cheile și TTL.
5. Cere /api/categories; verifică și categories::all.
6. Trimite POST /api/cache/clear și verifică înainte de alt GET. Frontend-ul recitește automat și poate recrea imediat cheile.
7. Ca ADMIN, creează/modifică/șterge un produs. Verifică invalidarea înainte de următoarea citire.

Windows nativ:

```powershell
& "C:\Program Files\Memurai\memurai-cli.exe" --scan --pattern "products::*"
& "C:\Program Files\Memurai\memurai-cli.exe" TTL products::all
```

Mac/Linux:

```sh
redis-cli --scan --pattern "products::*"
redis-cli TTL products::all
```

Prin Docker:

```sh
docker compose -f database/compose.yaml exec -T redis redis-cli --scan --pattern "products::*"
docker compose -f database/compose.yaml exec -T redis redis-cli TTL products::all
```

TTL între 1 și 60 este normal. -2 înseamnă absent; recitește după expirare. -1 înseamnă fără expirare și necesită verificarea configurației.
Viteza singură nu demonstrează cache-ul; verifică cheile și testele.

## 6. Aceleași verificări ca pe solution

### 6.1. Rulează toate testele de completare

Windows: `.\setup.cmd check`. Mac/Debian: `bash setup.sh check`.
Comanda folosește `mvn -Plesson-check test`. H2 și cache-ul în memorie izolează testele; verifică separat PostgreSQL și Redis reale.

### 6.2. Include răspunsurile și în compilările obișnuite

În secțiunea principală `<properties>` din pom.xml înlocuiește:

```xml
<excludedGroups>lesson-complete</excludedGroups>
```

cu:

```xml
<excludedGroups>lesson-starter</excludedGroups>
```

Fă schimbarea după completarea exercițiilor; altfel instalarea va eșua corect la teste. Aceasta este configurația solution.

### 6.3. Adaugă cele două teste suplimentare din lecția 1

În `src/test/java/com/impact/ecommerce/Lesson1BackendApplicationTests.java`, înainte de ultima acoladă a clasei, adaugă metodele de mai jos. Păstrează cele trei teste existente. Importurile necesare există sau tipurile sunt scrise complet.

```java
    @Test
    void completedPracticeResponsesMatchLessonText() throws Exception {
        String body = "{\"name\":\"demo\"}";
        String[] methods = {"POST", "PUT", "PATCH", "DELETE"};
        String[] prefixes = {"youve posted: ", "your update is : ", "you have updated the : ", "youve deleted : "};
        for (int i = 0; i < methods.length; i++) {
            mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                    .request(org.springframework.http.HttpMethod.valueOf(methods[i]), "/api/practice")
                    .contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isOk()).andExpect(content().string(prefixes[i] + body));
        }
    }

    @Test
    void completedCorsAllowsEveryLessonMethod() throws Exception {
        for (String method : new String[]{"GET", "POST", "PUT", "PATCH", "DELETE"}) {
            mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                    .options("/api/practice").header("Origin", "http://localhost:5500")
                    .header("Access-Control-Request-Method", method))
                    .andExpect(status().isOk())
                    .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5500"))
                    .andExpect(header().string("Access-Control-Allow-Methods", org.hamcrest.Matchers.containsString(method)));
        }
    }
```

Cu aceste metode și toate răspunsurile completate, versiunea curentă are **21 de teste de aplicație reușite**.

### 6.4. Verificarea finală

- [ ] Textele lecției 1 sunt exacte și preflight-urile funcționează.
- [ ] Produsele vin din PostgreSQL; parolele sunt hash-uri; USER nu poate folosi rutele ADMIN.
- [ ] Redis are chei și TTL; toate scrierile invalidează; golirea funcționează.
- [ ] Swagger are Authorize și rutele documentate.
- [ ] Toate testele trec.
- [ ] Metodele completate nu mai aruncă LessonTodo.required(...).
- [ ] Nu ai pregătit pentru commit parole sau modificări din frontend.

Codul de mai sus reproduce comportamentul și testele solution. Comentariile TODO/Answer și formularea README nu schimbă funcționarea. Pentru prezentare identică, înlocuiește comentariile completate cu explicații și spune în README că răspunsurile sunt gata. Păstrează helperul LessonTodo pentru lecțiile viitoare.

## 7. Salvează în repository-ul tău

Pe ramura de lucru:

```sh
git add .
git diff --cached
git commit -m "feat: complete lessons 1 to 3"
git push -u origin HEAD
```

Deschide un PR către propriul main, citește întregul diff și integrează după verificări. Nu trimite modificări în repository-ul profesorului sau al frontend-ului.

## Probleme frecvente

| Simptom | Verificare |
| --- | --- |
| 501 | A rămas o excepție TODO în metoda necesară. |
| 401 după login | Verifică L2-6, expirarea și dacă ai repornit după obținerea tokenului. |
| USER primește 403 pe ADMIN | Corect; folosește contul ADMIN pentru acele rute. |
| Swagger fără Authorize | Completează L3-5 și repornește. |
| Nu apar chei Redis | Activează Redis local, repornește, completează adnotările și fă o citire. |
| Cheile reapar după golire | O citire le-a recreat; frontend-ul recitește imediat. |
| 503 | Redis este activat, dar inaccesibil. Pornește-l sau dezactivează caching-ul pentru lecțiile anterioare. |
| Eroare PostgreSQL | Verifică serviciul, baza și parola din fișierul local. |
| Build trece, check eșuează | Main exclude testele exercițiilor la build; check le include. |
