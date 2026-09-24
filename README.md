# Impact backend - solution

## 1. Get your copy

On GitHub, click **Use this template > Create a new repository**. Clone **your new repository** and open its folder in IntelliJ.

## 2. Set up once

| | Windows | Mac / Debian |
| --- | --- | --- |
| Install Java, Maven and Git | Double-click `setup.cmd` | `bash setup.sh` |

Set up [PostgreSQL](database/README.md): create the database, run the SQL files, and save your password in `application-local.properties`. Docker is optional.

## 3. Start and complete the lesson

Run commands from the project folder:

| | Windows PowerShell | Mac / Debian |
| --- | --- | --- |
| Start backend | `.\setup.cmd run` | `bash setup.sh run` |
| Check Lesson 2 answers | `.\setup.cmd check` | `bash setup.sh check` |

Keep PostgreSQL running. After **Started**, open **http://localhost:8080/**. **Ctrl+C** stops the backend; restart after editing.

**Lesson 1 and Lesson 2 answers are completed on this branch.** All lesson checks should pass. Student exercises are on [main](https://github.com/krovskiy/impact_backend2_starter/tree/main).

## 4. Save to your GitHub

```sh
git add .
git commit -m "Complete lesson exercises"
git push origin HEAD
```

Setup keeps your repository's origin and does not commit or push for you.

[Completed answers: solution branch](https://github.com/krovskiy/impact_backend2_starter/tree/solution).
