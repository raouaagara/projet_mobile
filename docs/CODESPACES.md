# Run the backend in GitHub Codespaces

Our 12 services + MySQL don't fit on an 8 GB PC. A **codespace** is a Linux machine in GitHub's cloud,
created from this repo: it runs the whole backend, and your PC only builds the app.

- The machine is described in [`.devcontainer/`](../.devcontainer): Java 17 + Maven, Python (AI service)
  and MariaDB, in Docker. Services run from their jars like on our PCs, so every `localhost` URL keeps working.
- You use it through VS Code in the browser (or your desktop VS Code).
- It is **not hosting**: it sleeps when nobody uses it and has a monthly free quota. For a server that is
  always on (final demo), we'll deploy to Azure later.

## Free quota (per person, per month)

| Account | Included | 2-core machine (8 GB) | 4-core machine (16 GB) |
|---|---|---|---|
| GitHub Free | 120 core-hours, 15 GB storage | 60 h | 30 h |
| GitHub Pro — free with the [Student Developer Pack](https://education.github.com/pack) | 180 core-hours, 20 GB | 90 h | 45 h |

The 2-core machine is enough. Without a payment method GitHub never charges you: the codespace is
blocked once the quota is used, until next month. To save hours:

- **Stop** it when you're done: [github.com/codespaces](https://github.com/codespaces) → `⋯` → *Stop codespace*
  (it also stops by itself when idle).
- **Delete** codespaces you don't use anymore: stopped ones still count as storage.

## First time (about 15 minutes)

1. Open **https://codespaces.new/Hchaichi8/Freelancer-Plateforme?quickstart=1**
   and create a codespace (2-core) on `main`, or on your own branch to try your changes.
2. VS Code opens in the browser. The first start builds all the services, then starts them. It is ready when
   the status table shows ✓ everywhere. Open a terminal (`Ctrl+ù` / `` Ctrl+` ``) and run `catchopp status` anytime.
3. Port **8085** (the gateway) must be **Public**, or the phone gets GitHub's login page instead of the API.
   The start script tries to do it. If `catchopp status` says it isn't, do it yourself: **PORTS** tab →
   right-click `8085` → *Port Visibility* → *Public*.
4. On your PC, run the app with the URL printed by `catchopp status`:
   ```bash
   cd mobile
   flutter run --dart-define=API_BASE_URL=https://<your-codespace>-8085.app.github.dev
   ```
   No `adb reverse` needed: the phone reaches it over Wi-Fi or 4G, and the emulator works too.

## Every day

- Open the codespace again from [github.com/codespaces](https://github.com/codespaces). The services restart
  by themselves, and only the ones whose code changed are rebuilt.
- The URL stays the same for the same codespace, so the app you installed keeps working.
- **Idle timeout:** requests from the phone don't count as activity. The codespace sleeps 30 minutes after
  you stop typing in it. Set it to 4 hours: [github.com/settings/codespaces](https://github.com/settings/codespaces) →
  *Default idle timeout* → `240`.
- New code: `git pull`, then `catchopp restart <name>` for the services that changed (or `catchopp stop` + `catchopp start`).
- Demo for everyone: while one person's codespace runs, the whole team can build the app with that URL.

## Commands

| Command | What it does |
|---|---|
| `catchopp status` | Which services are up + the URL for the app |
| `catchopp logs project` | Follow one service's log (`Ctrl+C` to quit) |
| `catchopp restart project` | Rebuild and restart one service |
| `catchopp start` / `catchopp stop` | Start / stop everything |

Names: `eureka gateway user project payment competence chat support skilltests community subscription referral ai`.
Logs are in `~/.catchopp/`, build errors in `~/.catchopp/build-<folder>.log`.

## Secrets (API keys, passwords)

Never put them in the repo. Add them at [github.com/settings/codespaces](https://github.com/settings/codespaces) →
*Secrets* → *New secret*, with access to `Freelancer-Plateforme`: `JWT_SECRET`, `MAIL_PASSWORD`,
`GEMINI_API_KEY` (and optionally `GEMINI_MODEL`, `OPENAI_API_KEY`). They become environment variables in your
codespace (stop and reopen it after adding one). Without them the services use their development defaults: sending
mail is off, and the AI features answer with a clear "AI isn't set up" message.

**The AI key:** create a free one at [aistudio.google.com/apikey](https://aistudio.google.com/apikey) and save it as
the `GEMINI_API_KEY` secret. It powers the AI tests, the AI CV assistant, review moderation and improvement, and the
support assistant (rewrite, summary, topic and priority), in module 1 the bio writer and the learning plan, and in
module 2 the proposal cover letter and job post writers. The job match score doesn't need a key: it runs on the `ai` service's own model. The model defaults to `gemini-3.5-flash-lite`; set
`GEMINI_MODEL` to change it without touching the code.

## Good to know

- The database starts **empty** in a new codespace: create your test accounts again. It is kept when the
  codespace stops, and lost when you delete it.
- While port 8085 is public, anyone with the URL can call the API: only use test data.
- Eureka's dashboard: **PORTS** tab → `8761` → *Open in browser*.
- A service shows ✗: `catchopp logs <name>` usually says why (most often: it started before MariaDB or Eureka
  were ready, then `catchopp restart <name>` fixes it).
