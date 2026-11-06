# Mobile app — work split (6 people, 6 branches)

The Flutter app (`mobile/`) covers **clients and freelancers** on **Android**. The admin dashboard stays in the
Angular web app.

The shared foundation is already on `main`: login/register, JWT session, HTTP client, router with role
guards, theme, bottom navigation, menu and a placeholder for every module. **Log in, open your module's
placeholder and replace it with real screens.**

## Who does what

| # | Module | Branch | Owner | Backend services | Main screens |
|---|---|---|---|---|---|
| 1 | Profile, Skills & Certifications | `feature/profile-skills` | _name_ | User, Competence & Review, SkillTests | 11 |
| 2 | Projects & Proposals | `feature/projects` | _name_ | Project | 10 |
| 3 | Contracts & Payments | `feature/contracts-payments` | _name_ | Project (`/Contract`), Payment | 10 |
| 4 | Messaging, Support & Availability | `feature/messaging-support` | _name_ | Communication, Support, Referral (`/availability`) | 6 + real-time |
| 5 | Subscriptions, Rewards & Referral | `feature/subscriptions-rewards` | _name_ | Subscription, Referral | 9 |
| 6 | Community | `feature/community` | _name_ | Community | 8 |

Each person works **only** in `mobile/lib/features/<module>/` and `mobile/test/features/<module>/`,
and declares their pages in `mobile/lib/features/<module>/<module>_routes.dart`.
The rest (core, shared, pubspec, gateway) goes through a pull request to `main` — see
[CONTRIBUTING.md](CONTRIBUTING.md).

For every endpoint, the web app already has working code. **Copy the request/response shapes from the
Angular service listed for your module.** All paths below go through the gateway (`Env.apiBaseUrl`).

---

## Module 1 — Profile, Skills & Certifications
**Folder:** `lib/features/profile/` · **Entry paths:** `AppPaths.profile`, `AppPaths.skillTests` (freelancer)

> ✅ **Done** on `feature/profile-skills`, including AI: CV skill extraction (FR/EN) with the new
> `backend/SkillExtractorAI` service, AI CV assistant and AI-generated tests (Premium).
> For other modules: `ProfilePaths.user(id)`, `ProfilePaths.review(userId:, projectId:)` and
> `userByIdProvider(id)` (name/avatar of any user) are ready to use.

Screens:
- My profile / public profile of another user (client & freelancer): bio, location, links, avatar, cover, skills, reviews, certifications
- Edit profile (avatar & cover are sent as base64 — use `toDataUri()` from `core/utils/image_utils.dart`)
- Freelancer onboarding after sign-up (skills, bio, CV upload)
- Skills: pick competences, upload a CV and auto-detect skills (AI)
- Reviews: list per freelancer; **review form** (opened by module 3 when a contract is completed)
- Leaderboard of freelancers by rating
- Skill tests: list by category → take a test → result → my certifications
- AI CV generator

Endpoints:
- `GET /users/{id}` · `PUT /users/update/{id}` · `GET /users/all`
- `POST /users/{userId}/competences` (body: list of ids) · `POST /users/{id}/upload-cv` (multipart `file`) · `GET /users/download-cv/{filename}`
- `GET /Competance/GetAllCompetance` · `GET /Competance/GetCompetance/{id}` · `POST /Competance/ParseCV`
- `GET /Review/GetReviewsByFreelancer/{id}` · `GET /Review/GetReviewsByClient/{id}` · `GET /Review/GetReviewsByProject/{id}`
- `POST /Review/AjouterReview` · `POST /Review/enhance` · `PUT /Review/ModifierReview` · `DELETE /Review/SupprimerReview/{id}`
- `GET /SkillTests/tests` · `GET /SkillTests/tests/{id}` · `GET /SkillTests/tests/{id}/questions` · `GET /SkillTests/categories`
- `POST /SkillTests/submit?userId=&testId=` (body: answers map) · `GET /SkillTests/certifications/user/{userId}`
- `POST /SkillTests/ai/generate` · `POST /SkillTests/ai/cv/analyze-text` · `POST /SkillTests/ai/cv/analyze-image`

Angular reference: `Services/user.service.ts`, `Services/competance.service.ts`, `Services/review.service.ts`,
`services-ayoub/skill-test.service.ts`, `services-ayoub/ai-cv.service.ts`, `Interfaces_Freelancers/profile-manager`, `Interfaces_Freelancers/onboarding`.

After a profile edit: `ref.invalidate(currentUserProvider)` so the menu header refreshes.
Expose a route others can open: `/profile/:userId` (public profile) and `/profile/review` (review form).

---

## Module 2 — Projects & Proposals
**Folder:** `lib/features/projects/` · **Entry path:** `AppPaths.projects` (1st tab)

> ✅ **Done** on `feature/projects`. Backend additions in ProjectMicroService:
> `GET /Project/proposals/freelancer/{freelancerId}`, one proposal per freelancer and only on OPEN projects (409),
> a notification to the freelancer when the client answers, `PUT /{id}/react?type=&previous=` to switch reaction.
> Note: the project JSON key is **`ExperienceLevel`** (capital E) — the backend ignores `experienceLevel`.
> For other modules: `ProjectPaths.details(id)` opens a project; `projectProvider(id)` gives it.
> Accepting a proposal opens `/contracts/new/:proposalId` (module 3); until module 3 exists, the app says "coming soon".

Screens:
- **Client:** dashboard / my projects, post a project (title, description, budget, category, job type, experience level, required skills, image), edit/delete, change status, see proposals, accept/reject a proposal
- **Freelancer:** job feed with search & filters (category, job type, budget), project details, submit a proposal (bid + estimated end date), my proposals / jobs, saved jobs
- Reactions on projects (like/love/haha/support)
- Notifications list (mark as read)

Endpoints:
- `GET /Project/allprojects` · `GET /Project/{id}` · `POST /Project/newproject` · `PUT /Project/update/{id}` · `DELETE /Project/delete/{id}`
- `PUT /Project/{id}/status` · `PUT /Project/{projectId}/react`
- `GET /Project/{projectId}/proposals` · `POST /Project/{projectId}/proposals` · `GET /Project/proposals/{proposalId}` · `PUT /Project/proposals/{proposalId}/status`
- `GET /Project/notifications/{userId}` · `PUT /Project/notifications/{notifId}/read`
- Read-only: `GET /Competance/GetAllCompetance` (to show required skills)

Enums: `Status` OPEN/ACTIVE/CLOSED · `StatusProposal` PENDING/ACCEPTED/REJECTED · `JobType` HOURLY/FIXED_PRICE ·
`ProjectCategory` WEB_DEVELOPMENT, MOBILE_DEVELOPMENT, UI_UX_DESIGN, DIGITAL_MARKETING, DATA_SCIENCE_AI, WRITING_TRANSLATION, VIDEO_ANIMATION, CUSTOMER_SUPPORT, FINANCE_ACCOUNTING, OTHER.

Angular reference: `Services/project-service.service.ts`, `Services/notification.service.ts`, `Interfaces_Client/*`, `Interfaces_Freelancers/freelancer-feed`, `project-details`.

⚠️ `allprojects` returns every project with its base64 image and no pagination → cache it in a provider,
filter on the phone, and use `ListView.builder`.
Handoff: when a client accepts a proposal, open module 3's contract creation page (`/contracts/new/:proposalId`).

---

## Module 3 — Contracts & Payments
**Folder:** `lib/features/contracts/` · **Entry paths:** `AppPaths.contracts` (2nd tab), `AppPaths.wallet`

> ✅ **Done** on `feature/contracts-payments`. Backend additions:
> paiementMS `POST /api/payments/escrow/contract/{contractId}/release {clientId}` (the client approves the work:
> escrow → freelancer, contract COMPLETED, project CLOSED), `GET /api/disputes/user/{userId}`, disputes only by the
> two parties and one at a time, escrow locks recorded as `ESCROW_LOCK` transactions, 404 for a missing wallet/escrow.
> ProjectMicroService `GET /Contract/proposal/{proposalId}`, one contract per ACCEPTED proposal (409), a clear 409 when
> the client's wallet is too low at signature.
> The "AI summary" is not done: the web page is empty and no backend exists; the contract page shows a local summary.
> Top-up is test money (no card payment), like on the web.

Screens:
- Contract list (client & freelancer) with status filter · contract details
- Create a contract from an accepted proposal (`/contracts/new/:proposalId`) · AI summary of the contract (virtual contract)
- Freelancer: review & **sign** (signature pad → base64 PNG with the `signature` package) or reject
- Client: mark as completed → release payment → open module 1's review form
- Wallet (client & freelancer): balance, top-up, escrows, transaction history
- Disputes: raise a dispute on a contract, follow its status

Endpoints:
- `POST /Contract/generate-from-proposal/{proposalId}` · `POST /Contract/create` · `GET /Contract/{id}`
- `GET /Contract/client/{clientId}` · `GET /Contract/freelancer/{freelancerId}`
- `PUT /Contract/{contractId}/sign` · `PUT /Contract/{contractId}/reject` · `PUT /Contract/{contractId}/complete`
- `GET /api/payments/wallet/{userId}` · `POST /api/payments/wallet/create/{userId}` · `POST /api/payments/wallet/create/freelancer/{userId}` · `POST /api/payments/topup`
- `POST /api/payments/escrow/lock` · `GET /api/payments/escrow/client/{clientId}` · `GET /api/payments/escrow/freelancer/{freelancerId}` · `GET /api/payments/escrow/contract/{contractId}`
- `GET /api/payments/transactions/{userId}`
- `POST /api/disputes/raise` · `GET /api/disputes/all`

Contract status: DRAFT, SENT, ACTIVE, CLOSED, REJECTED, COMPLETED, CANCELLED.

Angular reference: `Services/contract.service.ts`, `Services/payment.service.ts`, `Services/dispute.service.ts`,
`Interfaces_Client/contract-creation`, `virtual-contract`, `Interfaces_Freelancers/freelancer-contract-review`, `*-wallet`.

---

## Module 4 — Messaging, Support & Availability
**Folder:** `lib/features/messaging/` · **Entry paths:** `AppPaths.messages` (3rd tab), `AppPaths.support`,
`AppPaths.availability` (freelancer), `AppPaths.worldClock` (client)

> ✅ **Done** on `feature/messaging-support`. Real-time chat works on phones through the gateway: the gateway now
> proxies WebSocket upgrades on `/ws/**` and `/ws-support/**` (`lb:ws://`) and serves `/uploads/**` (on
> `chore/fix-eureka-registration`). Chat service additions: server-side moderation in English and French (replaces the
> web app's client-side Hugging Face check, no key in any app; refusals on `/user/{id}/queue/errors`, pre-check
> `POST /chat/moderate`), `GET /chat/conversations/{userId}/summary` (last message + unread count),
> `PUT /chat/conversations/{id}/read?userId=` (read receipts on `/queue/reads`), 10 MB uploads with gateway links.
> Support: ticket categories are now stable (scored, not "first keyword of an unordered map"); the tests build on
> Spring Boot 4. Support replies can't be pushed to users (no user identity on its socket), so the ticket page refreshes
> every 10 s. "Improve with AI" needs a TextRazor key on the server; without it the app says the text is kept.
> For other modules: `MessagingPaths.chatWith(userId)` opens or creates a conversation.

Screens:
- Conversations list · chat screen (send, edit, delete, react, send image/PDF) · start a conversation with a user
- Support: my tickets, create a ticket (AI text enhancement), ticket details + responses, live updates
- Freelancer availability: status, timezone, time slots
- Client world clock: freelancers' local time & availability

Real-time (package `stomp_dart_client`, same protocol as the web app):
```dart
StompClient(config: StompConfig.sockJS(url: Env.chatSocketUrl, onConnect: ...));
// send:      destination '/app/chat', body: jsonEncode(message)
// subscribe: '/user/$userId/queue/messages' | '/queue/updates' | '/queue/deletes'
// support:   StompConfig.sockJS(url: Env.supportSocketUrl) → '/user/$userId/queue/support'
```

Endpoints:
- `GET /chat/conversations/{userId}` · `GET /chat/messages/{conversationId}` · `POST /chat/conversation/create?user1=&user2=`
- `PUT /chat/messages/{id}` · `DELETE /chat/messages/{id}` · `PUT /chat/messages/{id}/reactions` · `POST /chat/upload` (multipart)
- `POST /api/tickets/create` · `GET /api/tickets/user/{userId}` · `GET /api/tickets/{id}` · `PUT /api/tickets/update/{id}`
- `POST /api/tickets/{id}/responses` · `GET /api/tickets/{id}/responses` · `POST /api/tickets/enhance-text` · `POST /api/tickets/escalate/{id}`
- `GET /Referral/availability/profile/{userId}/or-create` · `PUT /Referral/availability/profiles/{id}` · `PUT /Referral/availability/profiles/heartbeat/{userId}`
- `GET|POST /Referral/availability/profiles/{profileId}/slots` · `PUT|DELETE /Referral/availability/slots/{id}` · `GET /Referral/availability/world-view`

Angular reference: `Services/chat.service.ts`, `Services/ticket.service.ts`, `services-ayoub/availability.service.ts`, `interface_communication/*`.

⚠️ Chat attachments come back as `http://localhost:8086/uploads/...`, which a phone can't open. It needs a
gateway route for `/uploads/**` → open a small PR to `main` for it.
⚠️ The web app calls Hugging Face for message moderation with a token in the frontend. Never put API keys in
the app: moderation must move to the backend.

---

## Module 5 — Subscriptions, Rewards & Referral (freelancer)
**Folder:** `lib/features/subscriptions/` · **Entry paths:** `AppPaths.subscriptions`, `AppPaths.rewards`, `AppPaths.referral`

> ✅ **Done** on `feature/subscriptions-rewards`. New server-side checkout in SubscriptionMicroService:
> `POST /Subscription/checkout/quote|start|confirm` — the server computes the price with the promo code, creates the
> Flouci payment and verifies it before activating the plan (same plan → renewed, other plan → replaces it), and a
> payment can't be reused. The web app's flow (pay, then call `/subscribe` from the browser) let anyone subscribe
> without paying and recorded a Premium payment on an active Base plan — the web should move to this checkout too.
> Without Flouci credentials it runs in **test mode** (simulated `TEST_` payments; refused once real credentials exist).
> Also fixed: a new subscription now expires the previous one; a plan past its end date is no longer "active";
> promo codes "usable after N subscriptions" accept N. Referral: not your own code, once per user, and the referrer now
> earns $5 in the reward wallet (before, no reward was ever created).
> ⚠️ Prices are shown in USD like the web app, but Flouci charges the same number in **TND** — agree on one currency.

Screens:
- Plans list · plan details · plan comparator
- Checkout with promo code → **Flouci payment in a WebView** (`webview_flutter`)
- My subscription dashboard (active plan, renewals, payment history)
- Rewards dashboard · spin wheel (once per period)
- Referral: my code (share with `share_plus`), invited users, earnings, referral wallet & leaderboards, donations

Flouci in the app: call `/Subscription/flouci/initiate` with a fake `successUrl` / `failUrl`
(e.g. `https://catchopp.app/payment/success`), open the returned link in a WebView, and in
`NavigationDelegate.onNavigationRequest` detect those URLs, close the WebView and call `/verify/{paymentId}`.

Endpoints:
- `GET /Subscription/plans` · `GET /Subscription/plans/{id}` · `POST /Subscription/subscribe`
- `GET /Subscription/user/{userId}/subscriptions` · `GET /Subscription/user/{userId}/active` · `PUT /Subscription/{id}/renew` · `GET /Subscription/{id}/payments`
- `POST /Subscription/flouci/initiate` · `GET /Subscription/flouci/verify/{paymentId}` (test mode: `/Subscription/flouci/test/initiate`, `/test/verify/{paymentId}`)
- `GET /api/promo-codes/available/{userId}` · `POST /api/promo-codes/validate` · `POST /api/promo-codes/calculate-discount` · `POST /api/promo-codes/apply`
- `GET /api/rewards/user/{userId}` · `GET /api/rewards/popups/{userId}` · `POST /api/rewards/spin-wheel/{userId}` · `GET /api/rewards/spin-wheel/can-spin/{userId}` · `GET /api/rewards/spin-wheel/history/{userId}`
- `GET /Referral/code/{userId}` · `GET /Referral/referrals/{userId}` · `GET /Referral/earned/{userId}` · `POST /Referral/use/{code}`
- `GET /api/wallet/{userId}` · `GET /api/wallet/{userId}/transactions` · `GET /api/wallet/leaderboards/earners`
- `POST /api/donations/send` · `GET /api/donations/sent/{userId}` · `GET /api/donations/received/{userId}`

Angular reference: `services-ayoub/subscription.service.ts`, `flouci.service.ts`, `promo-code.service.ts`,
`referral.service.ts`, `donation.service.ts`, `Interfaces_Rewards/*`, `Interfaces_Subscription/*`.

---

## Module 6 — Community
**Folder:** `lib/features/community/` · **Entry path:** `AppPaths.community` (4th tab)

> ✅ **Done** on `feature/community`. CommunityMicroService additions: `POST /api/group-members/join` (public groups
> only, once), `POST /api/groups?creatorId=` (creator = first admin), members-only posting in groups,
> `GET /api/posts/feed?groupId=|clubId=&userId=` (real comment/reaction counts + my reaction — the old
> `/group/{id}/user/{id}` returns zeros). Fixed: creating an **event** or a **club** without a status failed (required
> columns) — events are now PENDING until an admin approves them, clubs ACTIVE. Private groups have no join request
> flow: an admin adds members (raw `POST /api/group-members`).

Screens:
- Groups list · create a group · group page (join/leave, members)
- Posts feed in a group · create post · comments · reactions on posts and comments
- Events list · event details · create an event
- Clubs list · search by interest · club page · club dashboard (owner)

Endpoints:
- `GET|POST /api/groups` · `GET|PUT|DELETE /api/groups/{id}`
- `POST /api/group-members` · `GET /api/group-members/group/{groupId}` · `GET /api/group-members/user/{userId}` · `DELETE /api/group-members/{id}` · `GET /api/group-members/group/{groupId}/count`
- `GET|POST /api/posts` · `GET /api/posts/group/{groupId}` · `GET /api/posts/club/{clubId}` · `GET /api/posts/with-engagement` · `PUT|DELETE /api/posts/{id}`
- `POST /api/comments` · `GET /api/comments/post/{postId}` · `PUT|DELETE /api/comments/{commentId}`
- `POST /api/reactions` · `GET /api/reactions/post/{postId}/counts` · `GET|DELETE /api/reactions/post/{postId}/user/{authorId}` (same shape for `/api/comment-reactions/comment/...`)
- `GET|POST /api/events` · `GET /api/events/{id}` · `GET /api/events/group/{groupId}` · `GET /api/events/club/{clubId}`
- `GET|POST /api/clubs` · `GET /api/clubs/{id}` · `GET /api/clubs/search?interest=`

Angular reference: `interfaces_events/*.service.ts`, `interfaces_events/models.ts`.
Backend docs: `backend/CommunityMicroService/API_DOCUMENTATION_EVENTS_COMMUNITIES.md`.

---

## Links between modules

| From | To | How |
|---|---|---|
| 2 Projects (accept proposal) | 3 Contracts | `context.push('/contracts/new/$proposalId')` |
| 3 Contracts (completed) | 1 Review form | `context.push('/profile/review', extra: {...})` |
| Any module (tap a user) | 1 Public profile | `context.push('/profile/$userId')` |
| Any module ("Message") | 4 Chat | `context.push('/messages/new/$otherUserId')` |

Agree on these paths early: the owner of the target module creates the route, even as a placeholder, so the
others can link to it.

## Suggested milestones

1. **Week 1:** models + repositories for your endpoints, list screens with real data.
2. **Week 2:** details and forms (create / edit / actions).
3. **Week 3:** links between modules, error/empty states, polish.
4. **Week 4:** merge into `main`, test the full flow together (post → propose → contract → sign → pay → review).
