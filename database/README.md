# PostgreSQL: prepare once

**Use native PostgreSQL if Docker runs out of memory.** Choose one option below.

## Native PostgreSQL

Already installed? Keep your existing password and skip installation.

- **Windows:** use the [PostgreSQL installer](https://www.postgresql.org/download/windows/). Include the server, pgAdmin and command-line tools. Remember the `postgres` password; keep port **5432**.
- **macOS:** use the [PostgreSQL installer](https://www.postgresql.org/download/macosx/) with the same settings.
- **Debian:** run these commands:

```sh
sudo apt update
sudo apt install postgresql postgresql-client
sudo systemctl start postgresql
sudo -u postgres psql
```

In the Debian `psql` prompt, type `\password postgres`, choose a password, then `\q`.
See the [official Debian instructions](https://www.postgresql.org/download/linux/debian/).

### Create the database

From the **project folder**, run this command and enter your PostgreSQL password:

```sh
psql -h localhost -U postgres -d postgres -v ON_ERROR_STOP=1 -f database/create_database.sql
```

Windows says `psql` is missing? In PowerShell, first add your installed version's bin folder (example for version 16):

```powershell
$env:Path += ';C:\Program Files\PostgreSQL\16\bin'
```

On macOS with the EDB version 16 installer: `export PATH="/Library/PostgreSQL/16/bin:$PATH"`.

Copy `database/application-local.properties.example` into the project root as **application-local.properties**. Set your database username and password there. This file is ignored by Git.

**pgAdmin alternative:** create a database named `e-commerce`. The backend creates its tables and sample data on startup; no manual table scripts are needed. Do not paste the psql-only `create_database.sql` into Query Tool.

## Optional: Docker

If Docker is already installed and running:

- Windows: `.\setup.cmd db`
- Mac/Linux: `bash setup.sh db`

This starts PostgreSQL on **localhost:5432** and loads the tables/sample data on first use. The app's defaults already match it. No local properties file is needed.

If port 5432 is occupied, use native PostgreSQL above. If Docker reports insufficient memory, use native PostgreSQL too.
To stop: `docker compose -f database/compose.yaml stop`. Data is kept. Docker initializes a new database; the backend also runs the repeatable SQL on every startup, including with an existing Docker volume.

## Start and check

Start the backend: `.\setup.cmd run` or `bash setup.sh run`.
Open **http://localhost:8080/api/products** — expect six sample products on a fresh database.

To inspect the native database: `psql -h localhost -U postgres -d e-commerce`. For Docker: `docker compose -f database/compose.yaml exec postgres psql -U postgres -d e-commerce`.

```sql
\dt
SELECT name, price, stock FROM products;
SELECT email, role, password_hash FROM users;
```

**Connection refused:** start PostgreSQL. **Password failed:** fix `application-local.properties`. **Missing table:** restart the updated backend; it now creates missing tables before validation. **Schema mismatch:** existing columns are not automatically changed; apply the teacher's schema changes for that lesson.

The sample accounts and Docker password are for local classroom practice only. Re-running the SQL keeps existing records. Do not delete an existing database to fix an error.
