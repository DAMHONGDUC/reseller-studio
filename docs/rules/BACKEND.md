# Backend — rules, queries, indexes and functions

Read this when touching `firestore.rules`, `firestore.indexes.json`, anything
under `functions/`, or any `data/` method that queries Firestore or calls a
marketplace.

What is stored, and what a field means, is `docs/DATA_MODEL.md`. This file is
about how the backend is written.

## Security rules

- **`read` gets its own rule. Never fold it into `allow read, write`.** A query
  has no single document to test, so the backend has to prove it safe from the
  query's own filters — and that proof only works when the read condition is a
  plain constraint on a field. A combined rule needs a disjunction to also
  cover creates, which leaves a branch constraining nothing: **every query is
  denied while every write still succeeds.** The failure is vicious because a
  permission error on a read looks exactly like rules that were never deployed,
  so an afternoon goes into the deploy pipeline before anyone reads the rule.
  - The one combined rule left is `users/{uid}`, which is only ever fetched by
    document id and never queried. Split it the day anything queries it.
- **`app_config/current` is readable without an account, and nothing goes in
  it that a stranger may not read.** Owner's rule. `ForceUpdateGate` wraps the
  app above the router, so the config is read before anyone has signed in — a
  forced update is about the binary, not about a seller — and `signedIn()`
  denied that read on every cold start. The denial was worse than noise: the
  stream is swallowed and closed by `FirestoreAppConfigRepository`, and the
  repository provider does not watch auth, so nothing re-listened after
  sign-in and the whole session ran on `AppConfig.fallback`.
  - **The cost is that its email lists are world-readable.** `premium_emails`,
    `dev_mode_emails` and `blocked_emails` are now readable by anyone with the
    project id, which every binary carries. They stay because none of them is
    a credential and all three are already a grant this app cannot enforce
    client-side; **a new field that names a person more than an address does
    belongs in a Cloud Function, not in this document.**
  - It is the only public read in the file. Everything else needs an account,
    and business records need a membership.
- **Check both directions of ownership on a write** — the stored document *and*
  the incoming one. Without the second, a client rewrites the owner id and
  plants a record in someone else's account. `workspaces/{workspaceId}` is the
  reference: create asserts `request.resource.data.ownerId == request.auth.uid`
  and update asserts the incoming `ownerId` still equals the stored one.
- **Membership is the only ACL and nobody edits their own membership
  document** — hard rule 11. Every other rule is decided by that document, so a
  self-edit is a promotion to owner.
- **The audit log is append-only and written only by Cloud Functions** — hard
  rule 12.
- **A rule can read one document; it cannot count a collection.** Anything
  enforced against a total — the Free item and order ceilings, the seat limit —
  is decided by a Cloud Function and written into a document the rule reads.
  `workspaces/{id}/usage/current` is that document for the ceilings, and it is
  `allow write: if false` for exactly the reason the subscription document is.
  - **No ceiling is written in `firestore.rules`.** The numbers have one owner
    in `PlanLimits.byPlan` and one deliberate mirror in
    `functions/src/lib/firestore.ts`; the function writes a *verdict* and the
    rule reads a boolean, so a third copy never exists to go stale.
  - **The rules ceiling is not the product ceiling.** `ceilingGrace` puts the
    rule above the client gate on purpose: the count is recounted by a trigger
    and lags a write, so enforcing to the exact number would refuse a seller an
    action their own app had just allowed. The gate is the ceiling on use; the
    rule is the ceiling on abuse.
- **Rules tests read `firestore.rules` itself, never a copy.** A copy would let
  the two drift, which is the one way a rules test fails: passing while
  production is open. The standalone `test-rules` command and its CI step are
  deliberately absent by owner's rule, and nothing gates a release on them —
  the rules ship on the strength of the deploy. `npm --prefix functions run
  test:rules` is how they are run by hand; it is deliberately **not** the
  `test` script, because it needs the Firestore emulator and `test` is what a
  deploy runs.
- **`npm test` in `functions/` gates every deploy of the functions**, and it
  holds only what runs on plain node against the compiled `lib/`. That is where
  a check belongs when its failure mode is invisible until a seller taps a
  button — a callable with no region, a name the app calls that nothing
  exports. Both were real, and both shipped once.

## Queries

- **Every query is built from `WorkspaceCollections`** (`lib/core/firestore/`).
  It is the one class that builds a reference, and it cannot name a collection
  outside the workspace it was constructed for — that is what makes hard rule
  14 structural instead of a convention. Never build a `CollectionReference`
  by hand in a repository.
- **A query that reaches a collection group carries its own workspace filter.**
  Rules cannot be evaluated over a whole collection, and one forgotten `where`
  is a leak between two sellers.
- **Never put two kinds of record in one collection.** Each entity gets its
  own — no shared collection with a `type` field standing in for three
  schemas, because the rules, the indexes and the DTO then all have to branch
  on a value the database does not enforce.

## Indexes

- **Indexes and rules deploy together.** `melos run deploy-firebase-<flavour>` does both;
  deploying one without the other is how a screen that passed review returns
  `FAILED_PRECONDITION` in production.
- **A missing composite index fails at runtime, not at build.** A test can
  prove `firestore.indexes.json` contains what the queries need; it can never
  prove the project has them. Every entry in that file carries a `"//"` note
  naming the screen it serves — keep that up, or nobody can tell a live index
  from a leftover.

## Reading a document

- **Every field below the top level is optional, on both sides of the wire.** A
  DTO reads a missing field as absent, never as a substitute value — a missing
  cost is `null`, which renders `—` (hard rules 4 and 5), never `0`.
- **An unknown enum code maps to null, never to a wrong neighbour.** A document
  written by a newer build must not silently become the enum value that happens
  to sit next to it in the list.
- **A field's meaning is never repurposed in place.** Two builds are always in
  the wild, so redefining what a stored field means breaks the older one
  invisibly. Add a new field and leave the old one alone.
- **Every failure crossing this boundary goes through `FailureMapper.guard`**
  (hard rule 6), and the `catch` logs the full error object, not a sentence
  about it (hard rule 8).

## Cloud Functions

- **Every function a client dials by name pins its region**, and it is
  **the region the Firestore database is in** — owner's rule. `onCall` and
  `onRequest` take `clientFacing` from `functions/src/lib/runtime.ts`.
  - **Pinned rather than left to the default**, even while the two agree: a
    default is not an agreement between two sides of a wire. When they
    disagreed the failure was a `not-found` at the moment a seller tapped the
    button — nothing failed at build, at deploy, or at startup, and account
    deletion is a store requirement.
  - **The database's region, not the seller's or the developer's.** The
    triggers and the scheduler already sit where the database is, so a
    callable anywhere else buys every read and write inside one a round trip
    between continents.
  - **Moving it deletes and recreates every function**, because region is part
    of a function's identity — the deploy stops and names them rather than
    doing it, which is right. Changing it means changing `FUNCTIONS_REGION` in
    every flavour file under `env_assets/` as well.
  - `test/server_surface.test.mjs` fails if a new callable forgets the pin, if
    the region stops matching `FUNCTIONS_REGION` in `env/env.example.json`, or
    if a name in `CallableConstant` has no function behind it.
  - **Triggers and the scheduler deliberately do not take it.** A Firestore
    trigger has to sit in a region its database allows — Firebase's to pick,
    not ours to guess — and nobody addresses one by region anyway.
- **Functions are idempotent.** They are retried — by the platform, by a client
  that lost its answer, by a redeploy. A function that is only correct the
  first time is a function that double-charges.
- **Log structured JSON, and fail loud on an upstream error** — retry with
  backoff, never silently skip a cohort. A function that swallows a failure
  makes the missing records look like the sellers simply had none.
- **Group before fanning out to a paid API** — one call per group, never one
  per user — and dedupe anything user-visible, like a push, with an explicit
  window. Two functions each doing the honest thing is how a seller gets the
  same notification twice.
- **One upstream provider per kind of data, backend included.** Two providers
  let the number in a notification disagree with the number on the screen the
  seller opens to check it.
- **Fail open on anything that can lock a seller out.** A force-update gate
  blocks only on an explicit flag against a strictly newer build: offline, a
  missing config document, an unreadable field and a malformed value must all
  let them in. The failure mode of failing closed is an app nobody can open and
  no way to ship the fix.
- **Compare versions segment by segment as numbers, never as strings** —
  `"1.10.0" < "1.9.0"` is true for a string, so the gate fires on the build
  that was supposed to pass.

## Marketplaces and anything upstream

- **No secret ships in the binary and no token is used from the app** — hard
  rule 10. The app asks the backend, the backend asks eBay. Everything in the
  app still depends on the repository interface, so moving a call to a function
  is a data-source swap, not a rewrite.
- **A proxy concentrates quota.** What used to be per-device calls all land on
  one key, so anything the app can reach is rate-limited or one seller's retry
  loop burns the month.
- **Ask for what you need in one request** where the vendor bills per call
  rather than per dataset, and cache two shapes of the same data under
  different keys so one can never be served the other's entry.
- **A marketplace failure logs its shape, never its contents** — hard rule 9. A
  `FirebaseFunctionsException`'s `code` and `details` are exactly what is
  needed and exactly what a hand-written string throws away.
