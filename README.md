# Lesson 1 Backend

## First setup

1. Clone this project (or download and extract the ZIP).
2. Create **your own empty repository** at [github.com/new](https://github.com/new). Do not add a README, license, or .gitignore.
3. Run the launcher in the project folder:

| Computer | Setup |
| --- | --- |
| Windows | Double-click **setup.cmd** |
| macOS / Debian Linux | Open Terminal in the project folder and run **`bash setup.sh`** |

4. Paste your repository link, for example `https://github.com/your-name/your-project`.

The script installs **Java 21, Maven and Git**, checks your link and push access, builds/tests the project, **removes the teacher's origin and replaces it with yours**, then commits and pushes to **main**. Future pushes go to your repository.

There is **no GitHub CLI or scripted sign-in**. Git uses your usual credentials; its credential manager may ask for authentication if you have not used Git on this computer. A repository link alone does not grant push access.

Allow a few minutes and follow any system installation/password prompts. macOS installs Homebrew if needed; Debian asks for sudo access. Run as your normal user. Windows needs Microsoft's App Installer (WinGet); setup explains what to do if it is missing.

## Start the backend

From the project folder:

| Computer | Start |
| --- | --- |
| Windows | `.\setup.cmd run` |
| macOS / Debian | `bash setup.sh run` |

Wait for `Started`, then open **http://localhost:8080/api/practice**.
The response should be `api initialised`. Keep the terminal open; press **Ctrl+C** to stop.

If port 8080 is busy, use `.\setup.cmd run 8081` or `bash setup.sh run 8081`.

## If setup stops

- **Bad link:** paste the repository page URL, without `/tree/main` or `/blob/...`. HTTPS and GitHub SSH links are accepted.
- **Cannot access/push:** check the spelling, repository ownership, and your normal Git credentials.
- **Remote already has different commits:** use an empty repository for first setup. Setup never force-pushes or overwrites remote history.
- **Download/build failure:** fix the error shown and rerun the same launcher. Failed builds are not published.
- **Windows blocks scripts:** use `setup.cmd`. Organization policy may require administrator help.
- **Incomplete toolchain folder:** rename the exact folder shown by the error, then rerun setup.

You can rerun setup after editing to test, commit and push again. It skips empty commits and reuses installed Java/Maven. Existing Git identity is retained; if missing, this project's identity uses the repository owner and their GitHub noreply email.

Setup publishes all non-ignored changes and existing Git history. Use your intended repository. Existing Java installations and other local branches are retained.

## Lesson exercises

Follow [LESSON1_CHECKLIST.md](LESSON1_CHECKLIST.md) to finish CORS and the POST/PUT/PATCH/DELETE responses. Test with a JSON body such as `{"name":"demo"}`, using Postman or the [lesson frontend](https://github.com/Victoras23/impact_2_year_fe).

## Script maintenance

Only the two launchers live in the root. Platform scripts and offline tests are in `scripts/`. Java/Maven are installed outside the project, under `%LOCALAPPDATA%\impact-backend\toolchains` on Windows or `~/.local/share/impact-backend/toolchains` on macOS/Linux. The launchers select them automatically.

Run `python scripts/tests/test_setup.py` for offline URL/Git tests. They use temporary local repositories and never push to GitHub. Windows tests require PowerShell; Unix tests require Bash (Git for Windows includes it).

Installation references: [Adoptium API](https://github.com/adoptium/api.adoptium.net/blob/main/docs/cookbook.adoc), [Maven](https://maven.apache.org/download.cgi), [Homebrew](https://brew.sh/), [WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/install).
