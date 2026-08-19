# Testing priorities

Read this when writing or fixing tests.

## Never run the whole suite to verify a change

Owner's rule. Scope the run to what changed — the file, or the directory:

```sh
fvm flutter test test/features/pricing
fvm flutter test test/core/money/money_test.dart
```

A full run is minutes of waiting for an answer about three files, and the
noise from everything unrelated is where a real regression gets skimmed past.
CI runs the whole suite; that is what it is for.

Two exceptions, both narrow: a change to `core/` that everything imports, and
the run just before handing work over.

**`test/features/shot_tmp_test.dart` is a gitignored scratch harness that
hangs by design.** Exclude it from any run wide enough to pick it up.


Done: **(1) profit, margin, ROI and max-buy-price**, including the plan §11
worked example, and screen-level tests that assert the figures rendered
against the mock seed rather than eyeballing a screenshot.

**Done: (3) permissions.** `functions/test/firestore_rules.test.mjs` runs the
deployed `firestore.rules` against the emulator — `melos run test-rules`, which
starts and stops it itself and needs Java. It covers what the file cannot be
read to prove: that a viewer cannot write, that nobody edits their own
membership document (hard rule 11), that the first-member bootstrap clause
admits only the uid the workspace names as `ownerId` and only as `owner`, and
that the audit log, marketplace and subscription documents refuse every client
write (hard rules 10 and 12). **It lives under `functions/` because that is the
repo's only Node toolchain and CI already has the job** — rules are not
functions, and the directory is the only thing they share.

Still to do, in order:

2. **State transitions** (plan §29) — that listing an item without a price is
   refused, and that Quick Add with only a title is not.
4. **Repository boundary** — that every `data/` method maps its failures to
   `AppFailure` rather than leaking a `FirebaseException`.
5. **Widget tests** for forms and error states.

Two things about widget tests here, both learned the hard way:

- **`pumpScreen` in `test/support/pump_app.dart` pins the surface to
  1179×2556.** The default 800×600 is wider and much shorter than any phone,
  so it hides real overflows behind fake ones.
- **Warm the streams with `warmUp(container)`, not `await
  container.read(p.future)`.** The mock repositories are backed by a broadcast
  controller that never closes, so awaiting their future hangs until the test
  times out.
- **The clock is pinned, and both halves have to be.** `pumpScreen` and
  `mockContainer` seed the dataset against `testNow` *and* override
  `clockProvider` with `FixedClock(testNow)`. Pinning only the seed is what
  made the Home test fail as the calendar moved past it. A widget or provider
  that still calls `DateTime.now()` to derive something is the bug, not the
  test — see the `clockProvider` rule in the root `CLAUDE.md`.
