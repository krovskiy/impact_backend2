# PostgreSQL și Redis: pregătire locală

**Docker este opțional.** Pe calculatoare cu puțină memorie folosește PostgreSQL și Redis/Memurai instalate nativ.

## PostgreSQL nativ

Dacă este deja instalat, păstrează parola existentă și sari peste instalare.

- **Windows:** [installer PostgreSQL](https://www.postgresql.org/download/windows/). Include serverul, pgAdmin și instrumentele de linie de comandă. Reține parola utilizatorului `postgres`; păstrează portul **5432**.
- **macOS:** [installer PostgreSQL](https://www.postgresql.org/download/macosx/), cu aceleași opțiuni.
- **Debian:** execută:

```sh
sudo apt update
sudo apt install postgresql postgresql-client
sudo systemctl start postgresql
sudo -u postgres psql
```

În consola psql de pe Debian: `\password postgres`, alege parola, apoi `\q`. [Instrucțiuni oficiale](https://www.postgresql.org/download/linux/debian/).

### Creează baza

Din folderul proiectului:

```sh
psql -h localhost -U postgres -d postgres -v ON_ERROR_STOP=1 -f database/create_database.sql
```

Dacă PowerShell nu găsește psql, adaugă folderul versiunii instalate; exemplu pentru 18:

```powershell
$env:Path += ';C:\Program Files\PostgreSQL\18\bin'
```

Pe Mac, pentru installerul EDB 18: `export PATH="/Library/PostgreSQL/18/bin:$PATH"`. Înlocuiește 18 cu versiunea ta.

Alternativ, în pgAdmin creează baza **e-commerce**. Nu lipi `create_database.sql` în Query Tool: conține comenzi specifice psql.

Copiază `database/application-local.properties.example` în rădăcina proiectului cu numele exact **application-local.properties**. Completează utilizatorul și parola PostgreSQL. Fișierul este ignorat de Git. Un fișier numit `application-local.settings` nu este încărcat de aplicație.

Backend-ul execută automat `create_tables.sql` și `insert_data.sql` înainte de verificarea JPA. Tabelele lipsă sunt create; înregistrările existente nu sunt resetate. Modificarea coloanelor existente necesită actualizarea explicită a schemei pentru lecția respectivă.

## PostgreSQL prin Docker, opțional

Cu Docker instalat și pornit:

- Windows: `.\setup.cmd db`
- Mac/Linux: `bash setup.sh db`

Se pornește PostgreSQL pe **localhost:5432**. Setările implicite ale aplicației corespund containerului; nu ai nevoie de fișier local dacă nu ai schimbat parola.

Dacă portul este ocupat, folosește PostgreSQL deja instalat. Dacă memoria nu ajunge, folosește instalarea nativă.
Oprire: `docker compose -f database/compose.yaml stop`. Datele sunt păstrate. Nu șterge baza sau volumul pentru a rezolva o eroare.

## Verifică PostgreSQL

Pornește backend-ul cu `.\setup.cmd run` sau `bash setup.sh run`.
Deschide **http://localhost:8080/api/products**: într-o bază nouă sunt șase produse.

Conectare nativă: `psql -h localhost -U postgres -d e-commerce`.
Prin Docker: `docker compose -f database/compose.yaml exec postgres psql -U postgres -d e-commerce`.

```sql
\dt
SELECT name, price, stock FROM products;
SELECT email, role, password_hash FROM users;
```

**Connection refused:** pornește PostgreSQL. **Password failed:** corectează fișierul local. **Schema mismatch:** verifică baza selectată și actualizările de schemă. Conturile și parolele demonstrative sunt numai pentru practica locală.

<a id="redis-pentru-lectia-3"></a>
## Redis pentru lecția 3

### Instalare nativă, fără Docker

| Sistem | Comandă în folderul proiectului |
| --- | --- |
| Windows | `.\setup.cmd redis` |
| macOS / Debian | `bash setup.sh redis` |

Setup-ul obișnuit pregătește și Redis dacă nu există deja un server activ.
Pe Windows instalează Memurai Developer și cere aprobarea Windows pentru administrator. Pe Mac instalează Redis prin Homebrew și pornește serviciul utilizatorului. Pe Debian folosește pachetele `redis-server` și `redis-tools`.

Verificare pe Windows:

```powershell
& "C:\Program Files\Memurai\memurai-cli.exe" ping
```

Pe Mac/Linux: `redis-cli ping`. Rezultatul trebuie să fie **PONG**.

Un mesaj „comanda nu este recunoscută” indică lipsa instrumentului sau a căii PATH, nu demonstrează singur că serverul este oprit. Redeschide terminalul după instalare sau folosește calea completă.

Setup nu oprește serverele existente și nu le schimbă parolele/porturile. Pentru a înlocui containerul Redis al lecției cu Memurai:

```powershell
docker compose -f database/compose.yaml stop redis
.\setup.cmd redis
```

Memurai Developer este pentru dezvoltare/testare și se oprește după zece zile; rulează din nou comanda Redis pentru pornirea serviciului. [Instalare](https://docs.memurai.com/en/installation), [ediții](https://www.memurai.com/get-memurai).
Dacă instalarea eșuează, verifică mesajul și jurnalul indicat în `%LOCALAPPDATA%\impact-backend\setup-logs`. Acceptă solicitarea de administrator.

### Alternativă: numai Redis în Docker

Poți păstra PostgreSQL nativ:

```sh
docker compose -f database/compose.yaml --profile lesson3 up -d --wait redis
docker compose -f database/compose.yaml exec -T redis redis-cli ping
```

Containerul include `redis-cli`; nu trebuie instalat separat pe Windows.
Oprire: `docker compose -f database/compose.yaml stop redis`.

### Activează cache-ul

În **application-local.properties**, păstrează datele PostgreSQL și adaugă:

```properties
spring.cache.type=redis
spring.data.redis.host=localhost
spring.data.redis.port=6379
```

Repornește backend-ul. Pentru lecțiile anterioare poți folosi `spring.cache.type=none`. Swagger funcționează în ambele moduri.

### Inspectează cheile

După completarea TODO-urilor și o cerere la `/api/products`:

```sh
redis-cli --scan --pattern "products::*"
redis-cli TTL products::all
```

Pe Windows folosește `memurai-cli` sau calea completă a acestuia. Prin Docker:

```sh
docker compose -f database/compose.yaml exec -T redis redis-cli --scan --pattern "products::*"
docker compose -f database/compose.yaml exec -T redis redis-cli TTL products::all
```

TTL trebuie să fie între 1 și 60. `-2` înseamnă cheie absentă; `-1` înseamnă fără expirare.
`POST /api/cache/clear` golește cache-urile catalogului. Nu folosi FLUSHALL.
Frontend-ul recitește imediat produsele și poate recrea cheile.

**503:** Redis este activat, dar nu răspunde; verifică serviciul, portul și parola.
**501:** TODO-ul de golire nu este completat.
