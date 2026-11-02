# Testing priorities

Read when writing or fixing tests.

## Never run the whole suite to verify a change

Owner's rule. Run only what changed — the file or the directory:

```sh
fvm flutter test test/features/pricing
fvm flutter test test/core/money/money_test.dart
```

A full run is minutes of waiting for an answer about three files, and unrelated noise is where a real regression gets skimmed past. CI runs the whole suite; that is its job.

Two narrow exceptions: a change to `core/` that everything imports, and the run just before handing work over.

**`test/features/shot_tmp_test.dart` is a gitignored scratch harness that hangs by design.** Exclude it from any run wide enough to catch it.

## Status

**Done: (1) profit, margin, ROI and max-buy-price**, incl. the plan §11 worked example, plus screen tests that assert the rendered figures against the mock seed instead of eyeballing a screenshot.

**Done: (3) permissions.** `functions/test/firestore_rules.test.mjs` runs the deployed `firestore.rules` on the emulator. The suite stays as coverage, but owner's rule removed its standalone command and CI step. It proves what reading the file cannot:

- a viewer cannot write;
- nobody edits their own membership document (hard rule 11);
- the first-member bootstrap admits only the workspace's `ownerId`, and only as `owner`;
- the audit log and subscription documents refuse every client write (hard rule 12);
- a workspace member may maintain the seller-owned marketplace records.

**It lives under `functions/` because that is the repo's only Node toolchain** — rules are not functions; the directory is all they share.

Still to do, in order:

2. **State transitions** (plan §29) — listing an item with no price is refused; Quick Add with only a title is not.
4. **Repository boundary** — every `data/` method maps failures to `AppFailure`, never leaking a `FirebaseException`.
5. **Widget tests** for forms and error states.

## Widget tests

Three things learned the hard way:

- **`pumpScreen` in `test/support/pump_app.dart` pins the surface to 1179×2556.** The default 800×600 is wider and far shorter than any phone, so it hides real overflows behind fake ones.
- **Warm streams with `warmUp(container)`, not `await container.read(p.future)`.** Mock repositories sit on a broadcast controller that never closes, so awaiting their future hangs until timeout.
- **Pin the clock — both halves.** `pumpScreen` and `mockContainer` seed the dataset against `testNow` *and* override `clockProvider` with `FixedClock(testNow)`. Pinning only the seed made the Home test fail as the calendar moved on. A widget or provider still deriving from `DateTime.now()` is the bug, not the test (the `clockProvider` rule in root `CLAUDE.md`).

## The camera is tested through `FakeScannerPlatform`

`test/support/fakes/fake_scanner_platform.dart` replaces `MobileScannerPlatform.instance`: the real `MobileScanner` widget and controller run above it; only the hardware is fake.

| Member | Does |
|---|---|
| `scan(code)` | Holds a label up to the lens |
| `calls` | Records every start and stop |
| `startError` | Refuses the camera |

A scanner test that stubs `BarcodeCameraView` tests nothing the seller touches — the first-hit guard, the pause under the result screen and the refused-camera loop all live in the real widget.

The sample bottles in `test/support/fixtures/sample_bottles/` are the codes to scan: a test decodes their SVG bars back to digits, and the owned ones are `SeedDatasetConstant`'s.
