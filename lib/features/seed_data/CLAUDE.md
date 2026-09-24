# Seed data — filling a real workspace, from the dev menu

**More → General → Seed demo data** writes three of every table
into the workspace currently open. It is the only way to put rows in
front of someone, and it does it by writing real documents through the real
repositories — so what is on screen afterwards came back out of Firestore.

**It replaced the mock-data switch, and that switch is not coming back.** That
one swapped every repository for an in-memory fake and never wrote anything,
which meant two things this feature exists to undo:

- **The app a developer looked at was not the app a seller runs.** Nothing
  exercised a write path, so `data/` could be broken for weeks without a
  single screen noticing.
- **A fake business was one stale preference away from being shown as real.**
  `DataMode` was persisted, dev mode is granted by email in `app_config`
  (a release-build grant by definition), and the guard against showing a
  seller somebody else's invented inventory was two booleans deep. Deleting
  the mode deleted the failure.

The fakes were not deleted — they moved to `test/support/fakes/`, which is
where a fake belongs. `test/support/pump_app.dart` wires them, and
`FakeOverrides` is the one place that says which provider gets which.

## Rules

- **Three of each, and that is the whole size of it.** Owner's rule. Three
  items, three orders, three of every other table. A collection that grows
  past three is one nobody can check by eye, and checking by eye is the point
  — `SeedDataset` is written out row by row rather than generated so its
  arithmetic can be verified by hand.
- **The seed is coherent, not random.** Every item traces to a purchase, every
  purchase to a source, every order to an item that existed. Random rows would
  fill the screens and prove nothing.
- **Five properties are deliberate and must survive any edit**, because they
  are what the screens must handle and what a tidy dataset would hide:
  **one item has no cost** (so `—` appears and hard rule 5 is exercised),
  **one listing is stale and one failed to publish** (so Needs Attention has
  rows), **one order sold under cost** (so the loss colour renders),
  **one order has no payout** (so Payouts has work — hard rule 3), and
  **one expense is recurring and older than a month** (so Expenses' "Due now"
  block is populated). The two a test names have ids on
  `SeedDatasetConstant`; the rest are an implementation detail.
- **It empties the workspace before it fills it.** Owner's rule. Ids come from
  the seed and every write is an upsert, so the *dataset* was already
  idempotent — what it could not do is remove rows nobody seeded, and a
  workspace somebody had been typing into came back as the seed plus their
  leftovers. The sweep is what makes the workspace itself idempotent.
- **The sweep keeps the marketplaces and carriers a workspace is created
  with**, because the seed does not write them back: clearing them leaves a
  business with no platform to list on and no way to get one short of creating
  another workspace. That is
  `WorkspacePurgeRepository.deleteRecordsExceptDefaults`, not
  `deleteAllRecords` — the Delete all data button beside it still sweeps
  everything.
- **Every row keeps the seed's own dates.** The DTOs write `createdAt` from
  the entity rather than a server timestamp, which is what makes the business
  look lived-in — a listing that went stale weeks ago, an offer about to
  lapse. Stamping them all with "now" would empty Home's Needs Attention
  block, which is the screen worth looking at.
- **It is behind `devModeEnabledProvider` and nothing else.** No route, no
  deep link, no env flag: one card in one block of Settings.
- **Delete all data is the button beside it and does not live here.** It
  empties the open workspace instead of filling it, and the sweep belongs to
  `workspace/` because what it must not delete is the membership and the audit
  log — see `lib/features/workspace/CLAUDE.md`.

`test/features/seed_data/seed_data_seeder_test.dart` pins the size, that every
collection is written, that twice equals once, that the dates survive, and
that the two rows the screens are judged on are still there.
