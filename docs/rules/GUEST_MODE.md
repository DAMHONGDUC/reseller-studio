# Guest mode, the local database, and the one-way sync

Read this before touching auth, the router's redirect, any
`data/repositories/` implementation, or anything under `lib/core/local/`.

> **Status: this is the target, not the current code.** The rule is written
> before the work it governs, as `CLAUDE.md` requires. Nothing described here
> is built yet — do not read a paragraph below as a description of a file that
> exists. It becomes a description as each phase lands.

## The sentence

**The app works with no account. An account is what makes the records durable
and shareable, not what makes them possible.** Owner's rule, and it reverses
both the old hard rule 1 ("login is mandatory, there is no guest mode") and
the old "No local database" entry under Tech stack. `docs/rules/DECISIONS.md`
holds why.

A seller who has not signed in gets the whole app, not a reduced one: Quick
Add, the five tabs, filters, bulk actions, analytics. What they do not get is
anything that needs a server to mean something (below).

## Two stores, and only one is live at a time

| The seller is | Records live in | Written by |
|---|---|---|
| signed out (**guest**) | the **local Drift database**, on this device only | the local repository implementations |
| signed in (**linked**) | **Firestore**, whose own offline cache is the local half | the Firestore repository implementations |

**Never both.** After sign-in the local database is drained and dropped — it
is not a cache in front of Firestore and must never become one. Firestore's
offline persistence already is that cache, and a second copy in front of it is
a sync engine nobody asked for.

The switch is one provider per repository, reading `accountKindProvider`
(`guest | linked`) and handing back the local or the Firestore implementation
behind the **same `domain/repositories/` interface**. No screen, controller or
service knows which one it got. **Never write `if (isGuest)` at a call site** —
that is the old hard rule 1's point, surviving this rewrite intact.

## Why Drift, and why it is smaller than it looks

Hard rule 14 already models every table flat, with `workspaceId` as a column
and the composite key spelled `{workspaceId}_{id}`. **A flat Firestore table
already *is* a SQL table**, so the local schema is the same shape rather than a
reshape — which is the same argument hard rule 14 was written on.

The sync engine is a fraction of a real one, and the reason is that the guest
store is **write-only and short-lived**:

- **It never pulls.** There is no account to pull from.
- **It never merges.** Nothing else writes it.
- **It needs no `revision` / `syncedRevision` column and no tombstone table.**
  The whole store is pending by definition; sign-in drains all of it, and a
  guest's delete deletes locally with nothing upstream to tell.

Do not port those columns from the sibling app. They exist there because two
stores stay live forever; here one replaces the other.

## Sign-in: drain, then drop

Push order is **parents before children**, or a row lands pointing at one that
is not there yet:

```text
sources → purchases → categories → locations → marketplaces → carriers
        → items → listings → orders → offers → expenses
```

- **Restamp, do not rewrite.** A pushed row keeps its local id and gains the
  real `workspaceId` and `createdBy`. Every foreign key between two local rows
  stays valid, because only the column changed — the clean property hard rule
  14 bought.
- **Drop a row from the local store only once the server has confirmed it.** A
  kill mid-push costs a re-push, never a record.
- **The push is not a screen.** It runs behind the splash with the same gate
  `AppFreshInstall` uses, and nothing in the app waits on it afterwards.

### Which workspace it lands in

| The account being signed into | What happens |
|---|---|
| has **no** workspace | the guest workspace is pushed up whole, and becomes theirs |
| **already has** one or more | **ask.** A dialog names the account's workspaces and the local one, and the seller picks the destination |

Owner's rule, and the dialog is not optional: emptying a guest's stock into a
business that already has real books is a merge the seller may not want, and it
cannot be undone by a rule.

## Sign-out wipes the device

**Signing out leaves the app blank.** Owner's rule, and it is deliberately the
opposite of the sibling app, whose sign-out keeps every local row. The reason
is that a reseller's records belong to a business and a team rather than to a
person's own phone, so a device handed to somebody else must not still hold
them.

Order: sign out of every provider → `terminate()` → `clearPersistence()` →
empty the Drift database. The Firestore half throws `failed-precondition`
while any stream is open, so this runs above the app, not inside a screen —
the same constraint that put the fresh-install wipe in `SplashScreen`.

**A sign-out does not create a new guest session.** The app lands on the login
screen with an empty local store, and the seller starts a guest session again
only by choosing to use the app without an account.

## Uninstall is total loss, and the app says so

A guest's records live on the device and nowhere else, so deleting the app
deletes the business. Reinstalling is a fresh install
(`lib/core/fresh_install/`) and there is nothing to recover — **accepted by
the owner, deliberately, and therefore something the product must say out
loud rather than something the architecture quietly assumes.**

Two things carry it, and neither is optional:

- a standing prompt to sign in, which names what is at risk rather than
  advertising a feature;
- a local export, so a seller who will not sign in still has a copy.

## What a guest does not get

Everything whose truth is written by a Cloud Function, because there is no
caller for one to trust:

- the audit log (hard rule 12) and notifications,
- team and invitations — an invitation is addressed to an email account,
- plan limits and usage counting,
- anything that reads another device.

These are the only places an account is demanded. One guard decides, the way
`NavigationUtils.requireSignIn` did: **never an `if` at the call site.**

## Things that must not exist

Borrowed from the sibling app's data-flow spec, and true here for the same
reason — a seller cannot make a sync happen, so a sync they can see is a
control they cannot use:

- a sync button, row, indicator, screen or setting,
- a "last synced" timestamp or a progress bar,
- any flow gated on a sync completing, **including the first one after
  sign-in**,
- a rule that has to be remembered at every new write.

The one sync state a widget may read is *the first push for this account is
still running*, and only so a list can say it is putting the records up
instead of claiming there are none (hard rule 5).

## The invariant

**No user-facing flow ever awaits the network.** A save, a delete or a screen
that waits on a server is the bug this whole design exists to prevent — it was
already true for a signed-in seller through Firestore's offline persistence,
and guest mode must not be the thing that breaks it.

Pin it with a test that writes a record against a repository whose remote half
throws, and asserts the call returns.
