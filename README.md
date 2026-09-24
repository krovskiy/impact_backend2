# Impact Backend Year 2 - Survival Repo

[Recuperare rapidă: structura proiectului și lecțiile 1–3](docs/LESSONS1_3_CATCHUP.md)

## 1. Creează copia ta

Pe GitHub: **Use this template > Create a new repository**. Clonează **repository-ul tău** și deschide folderul în IntelliJ.

## 2. Pregătește calculatorul

| Acțiune | Windows | macOS / Debian |
| --- | --- | --- |
| Instalare Java, Maven, Git și Redis | Dublu clic pe `setup.cmd` | `bash setup.sh` |
| Doar Redis nativ | `.\setup.cmd redis` | `bash setup.sh redis` |

Pe Windows se instalează Memurai; pe Mac/Linux, Redis. Acceptă solicitările de administrator când apar. Un server existent este păstrat. **Docker este opțional.**

Pregătește [PostgreSQL](database/README.md): creează baza și salvează parola în `application-local.properties`. Backend-ul creează tabelele și datele demonstrative la pornire.

## 3. Pornește și verifică

| Acțiune | Windows PowerShell | macOS / Debian |
| --- | --- | --- |
| Pornire backend | `.\setup.cmd run` | `bash setup.sh run` |
| Verificare răspunsuri | `.\setup.cmd check` | `bash setup.sh check` |

După mesajul **Started**, deschide **http://localhost:8080/**. PostgreSQL trebuie să ruleze. **Ctrl+C** oprește backend-ul; repornește-l după modificări.

**Pe această ramură sunt completate răspunsurile pentru lecțiile 1–3.** Exercițiile sunt pe [main](https://github.com/krovskiy/impact_backend2_starter/tree/main). Urmează [lecția 3](LESSON3_CHECKLIST.md) pentru activarea Redis și Swagger.

## 4. Salvează lucrul

În repository-ul tău:

```sh
git switch -c feature/lectia-mea
git add .
git commit -m "feat: complete lesson exercises"
git push -u origin HEAD
```

Deschide un Pull Request către propriul `main` și verifică diferențele. Setup păstrează origin și nu face automat commit sau push.

Liste de verificare: [lecția 1](LESSON1_CHECKLIST.md), [lecția 2](LESSON2_CHECKLIST.md), [lecția 3](LESSON3_CHECKLIST.md). [Răspunsuri: solution](https://github.com/krovskiy/impact_backend2_starter/tree/solution).
