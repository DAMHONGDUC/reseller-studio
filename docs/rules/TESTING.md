# Testing priorities

Read this when writing or fixing tests.

Done: **(1) profit, margin, ROI and max-buy-price**, including the plan §11
worked example, and screen-level tests that assert the figures rendered
against the mock seed rather than eyeballing a screenshot.

Still to do, in order:

2. **State transitions** (plan §29) — that listing an item without a price is
   refused, and that Quick Add with only a title is not.
3. **Permissions** — that a `viewer` cannot write and that nobody can edit
   their own membership document. Firestore rules tests against the emulator.
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
