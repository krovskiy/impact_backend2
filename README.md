# Impact Backend Year 2 - Survival Repo

[Fast catch-up: understand the project and complete Lessons 1-3](docs/LESSONS1_3_CATCHUP.md)

## 1. Get your copy

On GitHub, click **Use this template > Create a new repository**. Clone **your new repository** and open its folder in IntelliJ.

## 2. Set up once

| | Windows | Mac / Debian |
| --- | --- | --- |
| Install Java, Maven and Git | Double-click `setup.cmd` | `bash setup.sh` |

Set up [PostgreSQL](database/README.md): create the database and save your password in `application-local.properties`. Tables and sample data are prepared automatically when the backend starts. Docker is optional.

## 3. Start and complete the lesson

Run commands from the project folder:

| | Windows PowerShell | Mac / Debian |
| --- | --- | --- |
| Start backend | `.\setup.cmd run` | `bash setup.sh run` |
| Check all lesson answers | `.\setup.cmd check` | `bash setup.sh check` |

Keep PostgreSQL running. After **Started**, open **http://localhost:8080/**. **Ctrl+C** stops the backend; restart after editing.

**Completed answers for Lessons 1, 2 and 3 are on this branch.** Student TODOs are on [main](https://github.com/krovskiy/impact_backend2_starter/tree/main). Follow [Lesson 3](LESSON3_CHECKLIST.md) to enable Redis and test Swagger.

## 4. Save to your GitHub

```sh
git switch -c feature/my-lesson
git add .
git commit -m "Complete lesson exercises"
git push -u origin HEAD
```

Open a pull request to your own main and review the diff. Lesson 3 adds optional Redis and Swagger: follow its checklist.

Setup keeps your repository's origin and does not commit or push for you.

[Completed answers: solution branch](https://github.com/krovskiy/impact_backend2_starter/tree/solution).
