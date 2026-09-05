# Mock data — the app runs fully before Firebase exists

**More → Settings → Mock data** swaps every repository for an in-memory one
seeded with a coherent demo business (`features/mock_data/`). It is off unless
`MOCK_DATA_DEFAULT` says otherwise (`docs/rules/COMMANDS.md`), so a dev run
opens the app a new seller would see.

**It is not visible while signed out, and that is not a bug to fix here.**
Four tabs render `SignedOutView` (hard rule 1) and `WorkspaceGuard` keeps
every business stream empty without a workspace — so mock data needs a session
and a workspace exactly like live data does. The switch is reachable signed
out because Settings is; what it changes is not.

- `DataMode` is **persisted** (unlike the auth bypass, which is a build flag),
  because it is a setting a developer toggles from inside the running app. It
  therefore carries two guards. `DataModeController` refuses to return `mock`
  without dev mode whatever is stored; and every repository provider tests
  `devModeEnabledProvider` **before** it reads the mode. Keep that test first
  when adding a provider — put it second and the fake business is one stale
  preference away. Showing a user a fake business as if it were theirs is
  worse than any crash.
- **The guard used to be `const` and no longer is.** It was
  `DevFlags.isDebugOrProfile`, false at compile time in release, so the mock
  branch folded away and the in-memory repositories and their seed left the
  binary. Dev mode is now also granted by email in `app_config` (owner's
  rule), which is a release-build grant by definition, so the branch survives
  compilation and the seed ships — unreachable unless the config names the
  signed-in account. why: see `docs/rules/DECISIONS.md` § Dev mode is granted
  by email.
- **`appConfigRepositoryProvider` is the one repository mock mode does not
  swap**, and it cannot be: dev mode is read out of `app_config`, so mocking
  the repository that supplies it is a circular dependency. It returned
  `AppConfig.fallback` anyway, which is what a build with no Firebase gets.
- **The seed is coherent, not random.** Every item traces to a purchase, every
  purchase to a source, every order to items that existed, and the totals add
  up by hand — `test/features/screens_with_mock_data_test.dart` asserts the
  arithmetic. Random rows would fill the screens and prove nothing.
- Five properties of the seed are deliberate and must survive edits to it:
  **some items have no cost** (so `—` appears and hard rule 5 is exercised),
  **some listings are stale and one failed to publish** (so Needs Attention
  has something in it), **one order sold under cost** (so the loss colour
  renders somewhere), **one recurring expense is older than a month** (so
  Expenses' "Due now" block has a row rather than being a section nobody sees
  populated), and **three sold orders have no payout recorded** (so Payouts has
  something to reconcile rather than an empty screen).
- **Nothing is persisted.** A restart re-seeds, so the dataset stays the
  known-good one the tests are written against.
- **Live mode is real now.** Every repository provider hands out its Firestore
  implementation; what it throws on is a missing workspace, which is a routing
  bug and says so out loud.
- **`DemoDataSeeder` is the other direction and the reason this feature earns
  its keep beyond development.** It takes the same seed and writes it through
  whatever repositories are live, so a brand new account can be demonstrated
  instead of showing five empty tabs — More → Settings → Seed demo data, debug
  builds only. Ids come from the seed and every write is an upsert, so running
  it twice replaces the demo business rather than doubling it. It is also the
  only thing that drives every live write path in one run, which makes it the
  fastest way to find out whether `data/` actually works against Firestore.
  `test/features/mock_data/demo_data_seeder_test.dart`.

Delete this feature when the real data layer is trusted — but note that
`DemoDataSeeder` outlives the switch: it is about filling a real workspace,
not about faking one.
