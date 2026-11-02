# Backend — rules, queries, indexes and functions

Read when touching `firestore.rules`, `firestore.indexes.json`, anything under `functions/`, or a `data/` method that queries Firestore or calls a marketplace.

What is stored, and what a field means: `docs/architecture/DATA_MODEL.md`. This file is how the backend is written.

## Security rules

- **`read` gets its own rule. Never fold it into `allow read, write`.** A query has no single document to test, so the backend must prove it safe from the query's own filters — which works only when the read condition is a plain field constraint. A combined rule needs a disjunction to cover creates too, leaving a branch that constrains nothing: **every query is denied while every write succeeds.** Vicious, because a denied read looks exactly like undeployed rules, so an afternoon goes into the deploy pipeline before anyone reads the rule.
  - The one combined rule left is `users/{uid}`, only ever fetched by id, never queried. Split it the day anything queries it.
- **`app_config/current` is readable with no account; put nothing in it a stranger may not read.** Owner's rule. `ForceUpdateGate` wraps the app above the router, so the config is read before sign-in — a forced update targets the binary, not a seller — and `signedIn()` denied that read on every cold start. Worse than noise: `FirestoreAppConfigRepository` swallows and closes the stream, and the repository provider does not watch auth, so nothing re-listened after sign-in and the whole session ran on `AppConfig.fallback`.
  - **The cost: its email lists are world-readable.** `premium_emails`, `dev_mode_emails` and `blocked_emails` are readable by anyone with the project id, which every binary carries. They stay: none is a credential, and all three are grants the app cannot enforce client-side. **A new field naming a person by more than an address belongs in a Cloud Function, not this document.**
  - It is the file's only public read. Everything else needs an account; business records need a membership.
- **Check both directions of ownership on a write** — the stored document *and* the incoming one. Without the second, a client rewrites the owner id and plants a record in someone else's account. Reference: `workspaces/{workspaceId}` — create asserts `request.resource.data.ownerId == request.auth.uid`; update asserts the incoming `ownerId` equals the stored one.
- **Membership is the only ACL; nobody edits their own membership document** — hard rule 11. That document decides every other rule, so a self-edit is a promotion to owner.
- **The audit log is append-only, written only by Cloud Functions** — hard rule 12.
- **A rule can read one document; it cannot count a collection.** Anything enforced against a total — Free item and order ceilings, the seat limit — is decided by a Cloud Function and written to a document the rule reads. `workspaces/{id}/usage/current` is that document for ceilings, `allow write: if false` for the same reason as the subscription document.
  - **No ceiling is written in `firestore.rules`.** The numbers have one owner, `PlanLimits.byPlan`, and one deliberate mirror in `functions/src/lib/firestore.ts`. The function writes a *verdict* and the rule reads a boolean, so no third copy exists to go stale.
  - **The rules ceiling is not the product ceiling.** `ceilingGrace` puts the rule above the client gate on purpose: a trigger recounts, lagging a write, so enforcing the exact number would refuse an action the app just allowed. The gate caps use; the rule caps abuse.
- **Rules tests read `firestore.rules` itself, never a copy.** A copy lets the two drift — the one way a rules test fails: passing while production is open.
  - The standalone `test-rules` command and its CI step are absent by owner's rule; nothing gates a release on them — rules ship on the strength of the deploy.
  - Run them by hand with `npm --prefix functions run test:rules`. It is **not** the `test` script: it needs the Firestore emulator, and `test` is what a deploy runs.
- **`npm test` in `functions/` gates every functions deploy** and holds only what runs on plain node against compiled `lib/`. A check belongs there when its failure is invisible until a seller taps a button — a callable with no region, a name the app calls that nothing exports. Both were real; both shipped once.

## Queries

- **Every query is built from `WorkspaceCollections`** (`lib/core/firestore/`). It is the one class that builds a reference, and it cannot name a collection outside its workspace — that makes hard rule 14 structural, not a convention. Never build a `CollectionReference` by hand in a repository.
- **A collection-group query carries its own workspace filter.** Rules cannot be evaluated over a whole collection; one forgotten `where` leaks between two sellers.
- **Never put two kinds of record in one collection.** Each entity gets its own — no shared collection with a `type` field standing in for three schemas, or rules, indexes and DTO all branch on a value the database does not enforce.

## Indexes

- **Indexes and rules deploy together.** `make deploy-be-<flavour>` does both; deploying one alone is how a reviewed screen returns `FAILED_PRECONDITION` in production.
- **A missing composite index fails at runtime, not build.** A test can prove `firestore.indexes.json` has what queries need; never that the project has them. Every entry carries a `"//"` note naming the screen it serves — keep it up, or nobody can tell a live index from a leftover.
- **`test/core/firestore/query_indexes_test.dart` is that test, and it reads the repositories, not a hand-kept list.** It exists because the rule above was broken: every *base* list query — items, orders, listings, offers, expenses, every catalogue table — shipped with no index, because the declared ones all assumed a second filter. A real project answered `failed-precondition` on five collections at once; the app came up empty with nothing saying why.
  - It scans `lib/features/*/data/repositories/` for `.query…` chains, builds each one's `workspaceId` + equality filters + sort, and fails on any signature `firestore.indexes.json` does not cover — a prefix of a longer index counts as covered, as in Firestore.
  - It is a regex over Dart, not a parse, so it **also asserts it matched something**. A scanner that silently stops matching is worse than none: green forever.

## Reading a document

- **Every field below the top level is optional, on both sides of the wire.** A DTO reads a missing field as absent, never a substitute — a missing cost is `null`, rendering `—` (hard rules 4, 5), never `0`.
- **An unknown enum code maps to null, never a wrong neighbour.** A document from a newer build must not silently become whichever value sits next to it.
- **Never repurpose a field's meaning in place.** Two builds are always in the wild; redefining a stored field breaks the older one invisibly. Add a new field; leave the old one.
- **Every failure crossing this boundary goes through `FailureMapper.guard`** (hard rule 6), and the `catch` logs the full error object, not a sentence about it (hard rule 8).
- **A stream's failure is reported once, not once per retry.** `guard` wraps a future and a listener fails repeatedly, so `FirestoreStream` logs instead and remembers what it reported.
  - A Firestore listener retries underneath the app, so a building index or a device with no signal repeats the same error every few seconds. With `SdLogger.error` reporting to Crashlytics, one missing index became dozens of identical non-fatals in one launch.
  - The first failure is reported in full, and so is a *different* one; a repeat drops to `SdLogger.debug`; a snapshot arriving makes the next failure news again.
  - **The stream still carries every error to its watcher** — this changes what is recorded, never what the UI decides. `test/core/firestore/firestore_stream_test.dart` pins all three.

## Cloud Functions

- **Every function a client calls by name pins its region — the Firestore database's region.** Owner's rule. `onCall` and `onRequest` take `clientFacing` from `functions/src/lib/runtime.ts`.
  - **Pinned, not left to the default**, even while they agree: a default is no agreement between two ends of a wire. When they disagreed, the failure was `not-found` the moment a seller tapped — nothing failed at build, deploy or startup — and account deletion is a store requirement.
  - **The database's region, not the seller's or developer's.** Triggers and the scheduler already sit with the database, so a callable elsewhere adds an intercontinental round trip to every read and write inside it.
  - **Moving it deletes and recreates every function**: region is part of a function's identity. The deploy stops and names them instead — correct. Changing it also means changing `FUNCTIONS_REGION` in every flavour file under `env_assets/`.
  - `test/server_surface.test.mjs` fails if a new callable skips the pin, if the region stops matching `FUNCTIONS_REGION` in `env/env.example.json`, or if a `CallableConstant` name has no function behind it.
  - **Triggers and the scheduler do not take it, on purpose.** A Firestore trigger must sit in a region its database allows — Firebase picks, we don't guess — and nobody calls one by region.
- **Functions are idempotent.** The platform, a client that lost its answer, a redeploy — all retry. A function correct only the first time double-charges.
- **Log structured JSON; fail loud on an upstream error** — retry with backoff, never silently skip a cohort. A swallowed failure makes missing records look like sellers simply had none.
- **Group before fanning out to a paid API** — one call per group, never per user — and dedupe anything user-visible, like a push, with an explicit window. Two functions each doing the honest thing is how a seller gets one notification twice.
- **One upstream provider per kind of data, backend included.** Two providers let a notification's number disagree with the screen the seller opens to check it.
- **Fail open on anything that can lock a seller out.** A force-update gate blocks only on an explicit flag against a strictly newer build: offline, a missing config document, an unreadable field and a malformed value all let them in. Failing closed means an app nobody can open and no way to ship the fix.
- **Compare versions segment by segment as numbers, never as strings** — `"1.10.0" < "1.9.0"` is true for strings, so the gate fires on the build meant to pass.

## Marketplaces and anything upstream

- **No secret ships in the binary; no token is used from the app** — hard rule 10. The app asks the backend; the backend asks eBay. The app still depends on the repository interface, so moving a call into a function is a data-source swap, not a rewrite.
- **A proxy concentrates quota.** Per-device calls all land on one key, so anything the app can reach is rate-limited — or one seller's retry loop burns the month.
- **Ask for what you need in one request** where the vendor bills per call, not per dataset; cache two shapes of the same data under different keys so one is never served the other's entry.
- **A marketplace failure logs its shape, never its contents** — hard rule 9. A `FirebaseFunctionsException`'s `code` and `details` are exactly what is needed, and exactly what a hand-written string throws away.
