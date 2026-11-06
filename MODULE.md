# Module 3 - Messaging, Support & Availability

Workify (freelance marketplace) - one of the 5 modules of the project.

## Services and code
- Backend: `MSCommunication` (real-time chat over WebSocket, attachments, moderation, chat AI),
  `TechnicalSupportMS` (support tickets, SLA, help assistant), `ReferralMicroService` (`/availability`).
- App: `mobile/lib/features/messaging/`, tests in `mobile/test/features/messaging/`.

## Features
- Live chat: conversations, unread counts, read receipts, reactions, edit and delete, photos and files.
- Support requests: topic, priority, SLA, replies from the team in the app.
- Freelancer availability (status, working hours) and a world clock for clients.

## AI
- **Moderation by meaning** after the word list: insults without swear words, veiled threats, sexual content,
  payment outside Workify (scams). Fails open.
- **Suggested replies** in the chat - `POST /chat/ai/replies`.
- **Translate a message** into the phone's language - `POST /chat/ai/translate`.
- **Catch me up**: summary, decisions and to-dos of a conversation - `POST /chat/ai/summary`.
- **Help assistant** answering from the Workify help guide, and writing the support request when needed -
  `POST /api/tickets/assistant/ask` (guide: `TechnicalSupportMS/src/main/resources/help/workify-help.md`).
- **Ticket AI**: topic, priority, summary and "Improve with AI" for requests.

## Shared base (in every module branch)
- Backend: `eureka` (service discovery), `apigetway` (gateway on port 8085), `UserMicroService` (accounts, JWT, profiles).
- App: `mobile/lib/core` (network, router, theme, session), `mobile/lib/shared` (UI kit), `features/auth`, `features/shell`.
- AI: each service calls Gemini with the key from the `GEMINI_API_KEY` environment variable (never in the code);
  without a key the AI features answer a clear message and the rest of the app keeps working.
- Run everything on the Codespace: `catchopp start`, then the app with `--dart-define=API_BASE_URL=<gateway URL>`
  (see `docs/CODESPACES.md`).

This branch starts from `main`, so the whole app runs; the sections above list what belongs to this module.
Changes to this module are made here and go to `main` through a pull request.
