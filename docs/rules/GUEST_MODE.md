# Guest mode, the local database, and the one-way sync

Read before touching auth, the router's redirect, any `data/repositories/` implementation, or anything under `lib/core/local/`.

## The sentence

**The app works with no account. An account makes records durable and shareable, not possible.** Owner's rule; it reverses both the old hard rule 1 ("login is mandatory, there is no guest mode") and the old "No local database" Tech stack entry. `docs/rules/DECISIONS.md` holds why.

A signed-out seller gets the whole app, not a reduced one: Quick Add, the five tabs, filters, bulk actions, analytics. Only what needs a server to mean something is withheld (below).

## Two stores, one live at a time

| The seller is | Records live in | Written by |
|---|---|---|
| Signed out (**guest**) | The **local Drift database**, this device only | Local repository implementations |
| Signed in (**linked**) | **Firestore**, whose own offline cache is the local half | Firestore repository implementations |

**Never both.** After sign-in the local database is drained and dropped. It is not a cache in front of Firestore and must never become one: Firestore's offline persistence already is that cache, and a second copy in front of it is a sync engine nobody asked for.

The switch is one provider per repository: it reads `accountKindProvider` (`guest | linked`) and returns the local or Firestore implementation behind the **same `domain/repositories/` interface**. No screen, controller or service knows which it got. **Never write `if (isGuest)` at a call site** — the old hard rule 1's point, intact.

## Why Drift, and why it is smaller than it looks

Hard rule 14 already models every table flat, with `workspaceId` as a column and the composite key `{workspaceId}_{id}`. **A flat Firestore table already *is* a SQL table**, so the local schema is the same shape, not a reshape — hard rule 14's own argument.

The sync engine is a fraction of a real one, because the guest store is **write-only and short-lived**:

- **It never pulls.** There is no account to pull from.
- **It never merges.** Nothing else writes it.
- **It needs no `revision` / `syncedRevision` column and no tombstone table.** The whole store is pending by definition; sign-in drains all of it, and a guest's delete is local with nothing upstream to tell.

Do not port those columns from the sibling app. They exist there because two stores stay live forever; here one replaces the other.

## Sign-in: drain, then drop

Push **parents before children**, or a row lands pointing at one not there yet:

```text
sources → purchases → categories → locations → marketplaces → carriers
        → items → listings → orders → offers → expenses
```

- **Restamp, do not rewrite.** A pushed row keeps its local id and gains the real `workspaceId` and `createdBy`. Every foreign key between two local rows stays valid, since only the column changed — the clean property hard rule 14 bought.
- **Drop a local row only once the server confirms it.** A kill mid-push costs a re-push, never a record.
- **The push is not a screen.** It runs behind the splash with the same gate `AppFreshInstall` uses; nothing in the app waits on it afterwards.

### Which workspace it lands in

| The account signed into | What happens |
|---|---|
| Has **no** workspace | The guest workspace is pushed up whole and becomes theirs |
| **Already has** one or more | **Ask.** A dialog names the account's workspaces and the local one; the seller picks the destination |

Owner's rule; the dialog is not optional. Emptying a guest's stock into a business with real books is a merge the seller may not want, and no rule can undo it.

## Sign-out wipes the device

**Signing out leaves the app blank.** Owner's rule, deliberately the opposite of the sibling app, whose sign-out keeps every local row. A reseller's records belong to a business and a team, not a person's phone, so a device handed to someone else must not still hold them.

Order: sign out of every provider → empty the Drift database → clear Firestore's cache. The first two are guaranteed; the third is best effort.

- **The cache is cleared through `FirestoreMaintenance.reset`, never by calling `terminate` directly.** Sign-out runs with the app on screen and re-subscribes `app_config`; a listener reaching the client while it terminates aborts the app on iOS. The reset detaches every listener first, holds new ones back, and re-attaches them all to the fresh client.
- **If it still fails, what remains is a cache nothing can read past**: every query carries a `workspaceId` filter (hard rule 14), and the next account does not match the last.
- **A sign-out starts no new guest session.** The app lands on login with an empty local store; the seller starts a guest session again only by choosing to use the app without an account.

## Uninstall is total loss, and the app says so

A guest's records live on the device alone, so deleting the app deletes the business. Reinstalling is a fresh install (`lib/core/fresh_install/`) with nothing to recover — **accepted by the owner, deliberately, so the product must say it out loud rather than the architecture quietly assume it.**

Two things carry it, neither optional:

- **A standing prompt on Home** — `_HomeGuestBanner`. It names what is at risk instead of advertising a feature, is **not dismissible**, and sits **above the premium banner**: the one place this app deliberately outranks an upsell, because one offers a seller more and the other says what they are about to lose. It stays silent until there is something to lose — warning about records not yet written is noise.
- **A guest has no export, by decision.** Owner's call; it upholds the older rule `PlanFeature.export` carries — *every export is paid* — against the pressure this feature put on it. Export is what Premium is really sold on, and a guest is on Free.

  **So signing in is a guest's only way to keep a copy, and nothing may imply otherwise.** The banner offers sign-in and names no other door; the privacy policy says exporting is part of Premium. Unlocking export for a guest later is a revenue decision, not a bug fix — it reverses this paragraph and `PlanFeature.export`'s own rule.

`test/features/local/guest_warning_test.dart` pins the banner in both directions.

## What a guest does not get

Everything whose truth a Cloud Function writes, because there is no caller for one to trust:

- the audit log (hard rule 12) and notifications;
- team and invitations — an invitation addresses an email account;
- plan limits and usage counting;
- anything reading another device.

Only these demand an account. One guard decides — `NavigationUtils.requireAccount`, which replaced `requireSignIn` and kept its point: **never an `if` at the call site.**

## Things that must not exist

Borrowed from the sibling app's data-flow spec, true here for the same reason — a seller cannot make a sync happen, so a sync they can see is a control they cannot use:

- a sync button, row, indicator, screen or setting;
- a "last synced" timestamp or progress bar;
- any flow gated on a sync completing, **including the first after sign-in**;
- a rule that must be remembered at every new write.

The one sync state a widget may read is *the first push for this account is still running* — only so a list can say it is putting records up instead of claiming there are none (hard rule 5).

**This list covers the device store's sync only.** Owner's call. A marketplace or supplier connection (hard rule 10) is different: its status and last error *are* shown, because the seller can act on them — reconnect, fix the account at the platform. Forbidden there as here: a manual "sync now" button, and any flow that waits on a sync.

## The invariant

**No user-facing flow ever awaits the network.** A save, delete or screen that waits on a server is the bug this design exists to prevent. It already held for a signed-in seller through Firestore's offline persistence; guest mode must not break it.

Pin it with a test that writes a record against a repository whose remote half throws, and asserts the call returns.

## Four decisions, and what each buys

### Drift's codegen is the one exception; committed output makes it safe

The Tech stack entry bans `riverpod_generator` because a codegen step that must run before the analyzer is honest is **a cost paid on every provider edit**. Drift's is paid on every *schema* edit — thirteen tables, written once, rarely changed — not the cost curve the original rule objects to.

**The generated files are committed**, and not for convenience: it is the clause that keeps what the original rule protected. A fresh checkout must analyze and test with no build step, so `make analyze` never depends on codegen having run. Regenerating is a deliberate act after a schema change, never a precondition for reading the repo.

### A guest's `createdBy` is a sentinel; `WorkspaceContext.uid` stays non-null

**Never make the uid nullable for a guest.** Twenty-one repositories take that context, and a nullable uid makes each decide separately what null means — the `if`-at-a-call-site failure, twenty-one times.

- A guest's uid is a **named constant**, so every signature below the context is untouched and no repository learns guest mode exists.
- The drain restamps `createdBy` to the real uid alongside `workspaceId`: **one restamp mechanism for both columns, never two.** Restamping is truthful — the same person created the record; they just had no account yet.
- The sentinel must never reach Firestore. In practice it cannot — `firestore.rules` checks `ownerId == request.auth.uid` when a workspace is created — but the drain asserts it anyway: a row attributed to a nonexistent account is a failure nobody would notice.

### No resume table: the local rows are the queue

The rule above — *drop a row only once the server confirms it* — already makes the drain resumable. **What remains in the local store is exactly what is still owed**, so a kill mid-drain needs no bookkeeping to recover — and bookkeeping is what can disagree with the rows it describes.

One fact must survive an interruption: **which workspace the seller chose** in the dialog. That is one row in one table, holding nothing else, in the Drift database so it dies with the data it describes. In `shared_preferences` it could outlive a wipe and claim a half-finished push for records that no longer exist.

### Photos: no guest limit, and they drain second

A signed-in seller has no photo count limit and neither does a guest; device disk is the only ceiling. Two facts make this cheap, both already true:

- **`FileUploader` is called when a photo is picked, not when the item is saved** — reasoning in `ItemFormController`. So a `LocalFileUploader` that copies into app-private storage and returns the path slots in with **no controller change**. The copy is required: `image_picker` returns a temporary path the OS may delete.
- **Rows drain before photos.** Rows are small and finish fast; a few hundred uploads on a phone connection do not. Nothing waits on either, and an item whose upload has not landed renders from its local file.

Build for this rather than be surprised: **`photoUrls` may hold a local path while signed in**, until that upload lands. Anything rendering a photo takes either form — not a guest-only concern.
