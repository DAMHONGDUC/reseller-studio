# Mock data — the app runs fully before Firebase exists

**More → Settings → Mock data** swaps every repository for an in-memory one
seeded with a coherent demo business (`features/mock_data/`). It is on by
default whenever auth is bypassed, because the two go together: a bypassed
session has no project and no user, so live mode would show an empty app and
a stream of permission errors.

- `DataMode` is **persisted** (unlike the auth bypass, which is a build flag),
  because it is a setting a developer toggles from inside the running app. It
  therefore carries its own guard: `DataModeController` refuses to return
  `mock` in a release build whatever is stored, and the Settings card is
  tree-shaken out entirely. Showing a user a fake business as if it were
  theirs is worse than any crash.
- **The seed is coherent, not random.** Every item traces to a purchase, every
  purchase to a source, every order to items that existed, and the totals add
  up by hand — `test/features/screens_with_mock_data_test.dart` asserts the
  arithmetic. Random rows would fill the screens and prove nothing.
- Three properties of the seed are deliberate and must survive edits to it:
  **some items have no cost** (so `—` appears and hard rule 5 is exercised),
  **some listings are stale and one failed to publish** (so Needs Attention
  has something in it), and **one order sold under cost** (so the loss colour
  renders somewhere).
- **Nothing is persisted.** A restart re-seeds, so the dataset stays the
  known-good one the tests are written against.
- Live mode throws `UnimplementedError` from any repository provider — the
  Firestore implementations do not exist yet. That is a named, explanatory
  failure rather than a null-check crash three frames later.

Delete this feature when the real data layer is done, the same way the auth
bypass goes.
