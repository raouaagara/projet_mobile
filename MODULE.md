# Module 5 - Community

Workify (freelance marketplace) - one of the 5 modules of the project.

## Services and code
- Backend: `CommunityMicroService` (groups, members, posts, comments, reactions, events, clubs, community AI).
- App: `mobile/lib/features/community/`, tests in `mobile/test/features/community/`.

## Features
- Groups (public, private, invite only), join and leave, members and roles.
- Posts with reactions and comments in groups and clubs; announcements.
- Events (approved by an admin) and clubs by interest.

## AI
- **Post and comment moderation** before publishing (harassment, hate, sexual content, threats, scams, spam),
  with the reason shown to the author.
- **Picked for you**: groups, clubs and upcoming events that fit the user's skills - `POST /api/groups/ai/recommend`.
- **Write with AI** in the post composer - `POST /api/posts/ai/draft`.

## Shared base (in every module branch)
- Backend: `eureka` (service discovery), `apigetway` (gateway on port 8085), `UserMicroService` (accounts, JWT, profiles).
- App: `mobile/lib/core` (network, router, theme, session), `mobile/lib/shared` (UI kit), `features/auth`, `features/shell`.
- AI: each service calls Gemini with the key from the `GEMINI_API_KEY` environment variable (never in the code);
  without a key the AI features answer a clear message and the rest of the app keeps working.
- Run everything on the Codespace: `catchopp start`, then the app with `--dart-define=API_BASE_URL=<gateway URL>`
  (see `docs/CODESPACES.md`).

This branch starts from `main`, so the whole app runs; the sections above list what belongs to this module.
Changes to this module are made here and go to `main` through a pull request.
