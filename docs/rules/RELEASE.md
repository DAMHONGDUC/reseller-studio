# Release

Read this before touching `env_assets/`, `packages/script-tools/flutter/prepare_env.sh`,
`packages/script-tools/flutter/build_ipa.sh`, anything under `ios/fastlane/`, or
`.github/workflows/release.yml`.

Two halves, and they are independent: **env config is what a build carries,
fastlane is what happens to the build afterwards.** The first works alone; the
second is useless without it.

## The hazard the whole pipeline exists for

| Kind of config | Reaches the app by | Files |
|---|---|---|
| Dart-visible values | `--dart-define-from-file=env/<flavour>.json` | `env/dev.json`, `env/prod.json` |
| Native SDK config | Read by the platform at build time | `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`, `ios/Runner/Info.plist` |

**Nothing ties the two together.** `env/prod.json` beside a dev
`GoogleService-Info.plist` compiles, installs, launches, and writes into the
wrong Firestore. Every guard below exists because of that one gap:
`packages/script-tools/flutter/prepare_env.sh` keeps the halves in step, and `verify_flavor_config` in
the beta lane is the last place a mismatch can be caught.

`ios/Runner/Info.plist` is in that list because it carries the Google sign-in
URL scheme — the reversed client id of **one** Firebase project. Wrong
flavour: the Google sheet opens and the callback never arrives.

## `env_assets/` is the local source of truth

Gitignored, one set per flavour, your own copies:

```text
env_assets/
  dev.json                          prod.json
  dev-google-services.json          prod-google-services.json
  dev-GoogleService-Info.plist      prod-GoogleService-Info.plist
  dev-Info.plist                    prod-Info.plist
```

`make env-dev` / `make env-prod` copies them where the build reads them.
The script's contract, and none of it is optional:

- **Every copy replaces the destination whole.** Owner's rule. The source's
  bytes land on the destination and nothing of what was there survives — never
  a merge, never "keep the keys the destination already had", never an edit
  that adds the flavour's values to somebody else's file. A merged file is the
  one state this script exists to make impossible: half of it says dev and half
  says prod, and nothing on disk says which half came from where. A tracked
  destination (`ios/Runner/Info.plist`) is overwritten like any other.
  - `make set-up` is the opposite and is not in conflict: it seeds
    `env/*.json` from the templates **only when the file is missing**, so it
    never touches a real one. `make env-<flavour>` is the command that installs a
    flavour, and installing means replacing.
- **Both `env/*.json` every run; only the native pair is flavour-picked.** One
  destination each, so there is nothing to choose at build time.
- **Destinations carry no `dev-`/`prod-` prefix.** Those exact paths are what
  the google-services gradle plugin and the Runner target read; a prefixed copy
  beside them is a file nothing opens.
- **Check every source first, copy after.** A run that dies on the third file
  leaves the tree half one environment and half the other, and nothing on disk
  says so.
- **It copies bytes and never reads them** (hard rule 9). The installed
  `Info.plist` is complete as supplied; the pipeline has no script that derives
  or patches a URL scheme after the copy.
- **`ios/Runner/Info.plist` comes from `env_assets/<flavour>-Info.plist`, like
  every other native file.** Owner's rule. The Runner target reads one path, so
  the flavour's plist is copied onto it rather than patched into the tracked
  one — a hand-edit that survives a flavour switch is the same hazard as a dev
  `GoogleService-Info.plist` beside `env/prod.json`, one file lower down.
**The flavour plists are complete build inputs.** Each one already carries its
Google sign-in callback alongside the shared usage strings, deep-link scheme
and orientations; the release workflow installs the selected file without a
second derivation step.

**`ios/Runner/Info.plist` is tracked, and `make env-<flavour>` overwrites it.** That
is deliberate and it leaves the working tree dirty: the installed file pins one
flavour, so **never commit it**.

## No one ever archives from Xcode

`packages/script-tools/flutter/build_ipa.sh` — `make build-ipa-dev` / `make build-ipa-prod` — is the only place an archive is made, and **the fastlane
lane shells out to it rather than calling `gym`**. The reason is not taste:
the app's whole configuration arrives through `--dart-define-from-file`, a flag
`xcodebuild`, `gym` and Product > Archive all know nothing about. An archive
made by any of them carries empty config and dies at runtime on
`[core/no-app] No Firebase App '[DEFAULT]' has been created` — a crash naming
nothing to do with the missing flag.

The script also fails early when `env/<flavour>.json` or the plist is missing
(**existence only, never contents**), wipes `build/ios/ipa` first so the glob
afterwards matches exactly one file and it is the one just built, and reads the
version out of `pubspec.yaml` rather than accepting a `--build-number` flag —
see `docs/rules/COMMANDS.md`.

## The lanes are the design system's; this app only declares itself

`ios/fastlane/Fastfile` is an `import` of
`packages/script-tools/flutter/fastlane/Fastfile` and one `sd_ios_app(...)` call.
It defines no lane, no helper and no constant. **Never re-implement a lane
here.** Every app embedding this design system releases through one pipeline,
and a lane copied into an app is one that stops getting the next fix — the
duplicate `beta` this repo carried had already drifted on three points before
it was removed: it never pushed the bump, it never recorded the design system's
commit, and it had no `upload` at all while `packages/script-tools/flutter/upload_ipa.sh`
was calling for one.

What belongs to the app is what the pipeline cannot know: the team, the bundle
ids, the Xcode targets and their entitlement files. They arrive through
`sd_ios_app`, whose `targets:` is **ordered** — the first is the app itself and
the id every upload, config check and TestFlight query uses; the rest are
extensions, which need profiles and export entries but are never uploaded.

Four lanes come with it:

| Lane | What it is |
|---|---|
| `beta` | the release: check, settle the number, sign, build, upload, symbols, commit |
| `upload` | the IPA already on disk, no rebuild — for a build that shipped and an upload that did not |
| `preflight` | everything `beta` does except the build, in three minutes (`make pre-build`) |
| `certificates` | mint or renew the certificate and profiles, **local only** |

## The beta lane's order is the design

Every step that can fail cheaply runs before the twenty-five minute one.

1. `verify_flavor_config` — the last place the hazard above is catchable.
2. **Settle the build number before the build**, `max(pubspec, TestFlight) + 1`,
   written **into `pubspec.yaml`**. TestFlight is consulted because App Store
   Connect refuses a number it has already seen for that version, on any
   branch; without `bump:` a used number is a hard error here rather than after
   twenty-five minutes.
3. CI only: `setup_ci` → `match(readonly: true)` → entitlement check → manual
   signing → write `ExportOptions.plist`.
4. Build, through `packages/script-tools/flutter/build_ipa.sh`.
5. Upload, **always carrying a release note**. Owner's rule: no build reaches
   TestFlight blank. `RELEASE_NOTES` — or `notes:` — is used when the release
   was given one, and the lane composes `<flavour> - <version> (<build>)`
   otherwise: `dev - 1.0.0 (20)`, `prod - 1.0.0 (21)`.
   - **The default is composed in the lane, never in `release_ios.sh`.** The build
     number is settled at step 2, inside the lane; the shell's `pubspec.yaml`
     still holds the previous one, so a note written before the lane runs names
     a build that is not the one uploaded.
   - **The note is the design system's, not this app's.**
     `packages/script-tools/flutter/fastlane/Fastfile` is imported by
     `ios/fastlane/Fastfile` and owns `sd_release_note` and
     `sd_upload_to_testflight`, so every app shipping through this tooling
     writes the same `<env> - <version name> (<version number>)`. The lane
     hands over the flavour, the version and the settled build number; it never
     hands over a finished string.
   - **The note is passed as `localized_build_info`, never as `changelog`.**
     They reach the same field, but `changelog` only PATCHES the build
     localizations that already exist — and a build just uploaded has none, so
     every note sent that way was dropped in silence, builds 2 to 10 included.
     Naming the locale is what makes pilot create the localization.
   - **The wait is the price and it is paid on every release now.** App Store
     Connect takes a note only once processing has finished, so
     `skip_waiting_for_build_processing` is off — nothing else in the lane
     reads the result, and macOS minutes bill at 10x.
6. dSYMs, best effort — the build is already up, and a symbol failure must not
   take the build-number commit down with it.
7. **Commit the build number, after the upload.** A bump commit with no build
   is a gap in the numbering; a build whose number is in no commit is the thing
   this ordering exists to prevent.
   - **Committed and pushed by the lane, and only on CI** (`bump && is_ci`).
     The workflow no longer pushes a step of its own. A local `bump:true` run
     rewrites `pubspec.yaml` and leaves it for you — `release_ios.sh` says so when
     it finishes.
   - **The design system's gitlink goes in the same commit**, and its short sha
     and subject go in the message. The workflow follows the submodule's `main`
     rather than the commit the parent pins, so without that line the IPA on
     TestFlight would contain UI the app repo never wrote down.

`make pre-build` is the `preflight` lane — everything a release depends on
except the build, three minutes instead of twenty-eight, and every credential
failure ever met surfaces in it. **`release-*` does not run it**: it is the
step to run by hand before starting a release.
**`flavor:` is optional there and is skipped rather than defaulted**:
defaulting to prod would fail a rehearsal on a dev machine over the one
question it was not asked.

`certificates` is **local only**, because CI runs `match(readonly: true)`: a
runner that can mint distribution certificates burns through Apple's limit of
three, one failed job at a time. `force:true` regenerates the *profiles*, not
the certificate, and is the only way a newly-enabled capability ever reaches
CI — `match` reuses an existing profile otherwise, which is the trap behind
every "profile doesn't include the … entitlement".

## Three subtleties that cost real time

- **`runner?` is not `is_ci`.** `is_ci` is true on a Mac rehearsing with
  `CI=true` — the very thing this file tells people to run — and `setup_ci`
  there creates a throwaway keychain, adds it to the search list, and never
  removes it. The shared certificate then lives in two keychains and `codesign`
  starts prompting at `exportArchive`, after the whole build. Gate `setup_ci`
  on the CI provider's own variable.
- **Multi-target export.** `flutter build ipa --export-method` generates an
  `ExportOptions.plist` mapping the main bundle id only — its own source calls
  multi-target apps a TODO. With automatic signing this never shows; with
  manual signing an extension gets no profile and `exportArchive` fails after
  the full build. The lane writes the plist itself with every id in it, and
  `packages/script-tools/flutter/build_ipa.sh` drops its own `--export-method` when a caller passes one.
  **One target today. Adding an extension means adding it to `sd_ios_app` in
  `ios/fastlane/Fastfile` and to the Matchfile** — the lane builds the plist
  from that list — and nothing will remind you.
- **An unreachable github.com is an SPM failure, not a build failure.** Every
  Swift package resolves from GitHub at the start of the archive, and when the
  network cannot reach it xcodebuild says `Couldn't fetch updates from remote
  repositories:` — with the reason on the next line, which flutter drops. Forty
  seconds, no cause named. `packages/script-tools/flutter/build_ipa.sh` checks
  reachability first and says so in ten. Nothing in the tree fixes it: connect
  to a VPN and run the release again.
- **Delete the empty auth variable.** Actions sets every `${{ secrets.X }}` a
  workflow names, empty string included, and `match` reads *both* auth
  variables from the environment regardless of what the call site passes —
  giving `remote: Duplicate header: "Authorization"`. Choosing one in code is
  not enough; the empty one has to leave `ENV`.

## The workflow

**Manual `workflow_dispatch` only** — a release is an act, not a side effect of
a push. What is load-bearing in `.github/workflows/release.yml`:

- **`case`, never a `${{ a && b || c }}` ternary** when picking the flavour's
  secret. The ternary falls through to its second branch when the first secret
  is merely *empty*, silently building prod with dev config.
- **`plutil -lint` straight after decoding the plist.** A truncated paste is
  otherwise indistinguishable from a good one until it throws on a device.
- **The URL scheme is derived from the plist just written**, not carried as a
  third secret.
- **Pin Ruby, then `bundle install`, in that order.** A gem binary only runs
  under the Ruby it was installed for.
- **`LANG` on the whole job**, or Ruby reads files as ASCII-8BIT and dies
  inside its own error reporter rather than on the line that failed.
- **Free-text notes travel as an environment variable, never as a lane
  argument**: spaces would split into extra fastlane arguments and a backtick
  would run.
- **The IPA is uploaded as an artifact.** If TestFlight later rejects the
  binary, the exact one that went out is still there.

`docs/release/PIPELINE.md` is the shape of a run; `docs/release/CREDENTIALS.md`
is what each credential is and where it lives. Everything not configured yet is
in `RELEASE_ACTIONS.md` — that file is the one place "it doesn't work" is
answered, and this pipeline did not get a second one.
