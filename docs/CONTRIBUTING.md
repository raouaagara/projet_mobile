# How we work

## Branches

```
main                           ← always builds and runs. Nobody pushes here directly.
 ├── feature/profile-skills         Module 1
 ├── feature/projects               Module 2
 ├── feature/contracts-payments     Module 3
 ├── feature/messaging-support      Module 4
 ├── feature/subscriptions-rewards  Module 5
 └── feature/community              Module 6
```

First time:
```bash
git clone https://github.com/Hchaichi8/Freelancer-Plateforme.git
cd Freelancer-Plateforme
git checkout feature/<your-module>
```

Every day:
```bash
git pull                         # get your own latest work
git fetch origin
git merge origin/main            # get the shared changes (do it at least twice a week)
# ... work ...
git add mobile/lib/features/<your-module> mobile/test/features/<your-module>
git commit -m "projects: add job feed with filters"
git push
```

## Stay in your folder

| You may change freely | Only through a pull request to `main` |
|---|---|
| `mobile/lib/features/<your-module>/**` | `mobile/lib/core/**`, `mobile/lib/shared/**` |
| `mobile/test/features/<your-module>/**` | `mobile/lib/core/router/app_paths.dart`, `app_router.dart` |
| the backend service your module owns | `mobile/pubspec.yaml` (new packages) |
| | `backend/apigetway/**`, `docker-compose.yml` |

For a shared change: create a small branch from `main` (e.g. `chore/add-uploads-route`), open a PR, get it
merged, then everyone runs `git merge origin/main`. Small shared PRs = no merge conflicts.

Backend services shared by two modules: **ProjectMicroService** (modules 2 and 3) and
**ReferralMicroService** (modules 4 and 5). Tell the other person before changing them.

## Merging into `main`

1. `flutter analyze` → no issues, `flutter test` → green.
2. Open a pull request `feature/<module>` → `main` and describe what's done, with screenshots.
3. One teammate reviews it and approves.
4. Merge. Then the others merge `main` into their branches.

Merge often (every 1–2 weeks) rather than one giant merge at the end.

## Code conventions (mobile)

- **State:** Riverpod (`Provider`, `FutureProvider`, `NotifierProvider`, `AsyncNotifierProvider`).
- **HTTP:** always `ref.watch(dioProvider)` — never create your own `Dio`. Wrap errors in `ApiException.from(e)`.
- **Models:** plain classes + `json_serializable` (see `core/models/app_user.dart`). After editing a model:
  `dart run build_runner build`, and commit the generated `.g.dart` file.
- **Navigation:** `context.push(...)` / `context.go(...)` with paths from `AppPaths` or your module's routes.
- **Current user:** `ref.watch(authControllerProvider).value` → `userId`, `role`; full profile: `ref.watch(currentUserProvider)`.
- **Loading / error / empty:** `AsyncValueView`, `ErrorView`, `EmptyView` from `shared/widgets/`.
- **Images from the API:** `imageFromApi(string)` handles base64 and URLs.
- **Folder layout inside a module:** `data/` (models, repositories) and `presentation/` (screens, widgets, providers).
- **Commits:** `<module>: <what changed>` in English, e.g. `contracts: sign contract with signature pad`.
- **Never commit** API keys, passwords or `.env` files.
