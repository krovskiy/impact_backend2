# Impact backend - solution

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

**Answers for the included lessons are completed here.** All lesson checks should pass. Student exercises are on [main](https://github.com/krovskiy/impact_backend2_starter/tree/main); more lessons will be added over time.

## 4. Save to your GitHub

```sh
git add .
git commit -m "Complete lesson exercises"
git push origin HEAD
```

Setup keeps your repository's origin and does not commit or push for you.

[Completed answers: solution branch](https://github.com/krovskiy/impact_backend2_starter/tree/solution).
