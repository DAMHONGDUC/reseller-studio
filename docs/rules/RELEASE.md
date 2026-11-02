# Release

Read before touching `env_assets/`, `packages/script-tools/flutter/prepare_env.sh`, `packages/script-tools/flutter/build_ipa.sh`, anything under `ios/fastlane/`, or `.github/workflows/release.yml`.

Two independent halves: **env config is what a build carries; fastlane is what happens to the build after.** The first works alone; the second is useless without it.

## The hazard the pipeline exists for

| Kind of config | Reaches the app by | Files |
|---|---|---|
| Dart-visible values | `--dart-define-from-file=env/<flavour>.json` | `env/dev.json`, `env/prod.json` |
| Native SDK config | Read by the platform at build time | `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`, `ios/Runner/Info.plist` |

**Nothing ties the two together.** `env/prod.json` beside a dev `GoogleService-Info.plist` compiles, installs, launches, and writes into the wrong Firestore. Every guard below exists for that one gap: `packages/script-tools/flutter/prepare_env.sh` keeps the halves in step; `verify_flavor_config` in the beta lane is the last place to catch a mismatch.

`ios/Runner/Info.plist` is listed because it carries the Google sign-in URL scheme — the reversed client id of **one** Firebase project. Wrong flavour: the Google sheet opens and the callback never arrives.

## `env_assets/` is the local source of truth

Gitignored, one set per flavour, your own copies:

```text
env_assets/
  dev.json                          prod.json
  dev-google-services.json          prod-google-services.json
  dev-GoogleService-Info.plist      prod-GoogleService-Info.plist
  dev-Info.plist                    prod-Info.plist
```

`make env-dev` / `make env-prod` copies them to where the build reads them. The script's contract, none of it optional:

- **Every copy replaces the destination whole.** Owner's rule. The source's bytes land on the destination; nothing that was there survives — never a merge, never "keep the keys it already had", never an edit adding the flavour's values to someone else's file. A merged file is the one state this script exists to prevent: half says dev, half says prod, and nothing on disk says which. A tracked destination (`ios/Runner/Info.plist`) is overwritten like any other.
  - `make setup` is the opposite, with no conflict: it seeds `env/*.json` from the templates **only when the file is missing**, so it never touches a real one. `make env-<flavour>` installs a flavour, and installing means replacing.
- **Both `env/*.json` every run; only the native pair is flavour-picked.** One destination each, so nothing is chosen at build time.
- **Destinations carry no `dev-`/`prod-` prefix.** The google-services gradle plugin and the Runner target read those exact paths; a prefixed copy beside them is a file nothing opens.
- **Check every source first, copy after.** A run dying on the third file leaves the tree half one environment, half the other, and nothing on disk says so.
- **It copies bytes and never reads them** (hard rule 9). The installed `Info.plist` is complete as supplied; no script derives or patches a URL scheme after the copy.
- **`ios/Runner/Info.plist` comes from `env_assets/<flavour>-Info.plist`, like every other native file.** Owner's rule. The Runner target reads one path, so the flavour's plist is copied onto it, not patched into the tracked one — a hand-edit surviving a flavour switch is the same hazard as a dev `GoogleService-Info.plist` beside `env/prod.json`, one file lower.

**The flavour plists are complete build inputs.** Each carries its Google sign-in callback beside the shared usage strings, deep-link scheme and orientations; the release workflow installs the chosen file with no second derivation step.

**`ios/Runner/Info.plist` is tracked, and `make env-<flavour>` overwrites it.** Deliberate, and it dirties the working tree: the installed file pins one flavour, so **never commit it**.

**A change to the tracked `Info.plist` goes into both `env_assets/*-Info.plist` in the same turn.** The next `make env-<flavour>` replaces the file whole, so a fix made only to the tracked copy is undone by the next flavour switch — how the locales and the portrait lock were lost twice. The flavour files should differ from the tracked one in the Google sign-in callback only; `portrait_orientation_test` and `shipping_locales_test` read the installed file and fail when they drift.

## Nobody archives from Xcode

`packages/script-tools/flutter/build_ipa.sh` — reached through `make release-ios-<flavour>` — is the only place an archive is made, and **the fastlane lane shells out to it instead of calling `gym`**. Not taste: the app's whole config arrives through `--dart-define-from-file`, a flag `xcodebuild`, `gym` and Product > Archive know nothing about. An archive from any of them carries empty config and dies at runtime on `[core/no-app] No Firebase App '[DEFAULT]' has been created` — a crash naming nothing about the missing flag.

The script also:

- fails early when `env/<flavour>.json` or the plist is missing (**existence only, never contents**);
- wipes `build/ios/ipa` first, so the glob afterwards matches exactly one file — the one just built;
- reads the version from `pubspec.yaml` instead of taking a `--build-number` flag — see `docs/rules/COMMANDS.md`.

## The lanes are the design system's; this app only declares itself

`ios/fastlane/Fastfile` is an `import` of `packages/script-tools/flutter/fastlane/Fastfile` plus one `sd_ios_app(...)` call. It defines no lane, helper or constant. **Never re-implement a lane here.** Every app on this design system releases through one pipeline, and a lane copied into an app stops getting the next fix. The duplicate `beta` this repo carried had drifted on three points before removal: it never pushed the bump, never recorded the design system's commit, and had no `upload` at all while `packages/script-tools/flutter/upload_ipa.sh` called for one.

The app owns what the pipeline cannot know: team, bundle ids, Xcode targets and their entitlement files. They arrive through `sd_ios_app`, whose `targets:` is **ordered** — the first is the app itself, the id every upload, config check and TestFlight query uses; the rest are extensions, which need profiles and export entries but are never uploaded.

Four lanes come with it:

| Lane | What it is |
|---|---|
| `beta` | The release: check, settle the number, sign, build, upload, symbols, commit |
| `upload` | The IPA already on disk, no rebuild — for a build that shipped and an upload that did not |
| `preflight` | Everything `beta` does but the build, in three minutes (`make pre-build`) |
| `certificates` | Mint or renew the certificate and profiles, **local only** |

## The beta lane's order is the design

Every step that can fail cheaply runs before the twenty-five-minute one.

1. `verify_flavor_config` — the last place the hazard above is catchable.
2. **Settle the build number before the build**: `max(pubspec, TestFlight) + 1`, written **into `pubspec.yaml`**. TestFlight is asked because App Store Connect refuses a number it has seen for that version, on any branch; without `bump:` a used number is a hard error here, not after twenty-five minutes.
3. CI only: `setup_ci` → `match(readonly: true)` → entitlement check → manual signing → write `ExportOptions.plist`.
4. Build, through `packages/script-tools/flutter/build_ipa.sh`.
5. Upload, **always with a release note**. Owner's rule: no build reaches TestFlight blank. Every note opens with `<flavour> - <version> (<build>)` — `dev - 1.0.0 (20)`, `prod - 1.0.0 (21)` — and that line alone is the default. `RELEASE_NOTES` — or `notes:`, or `NOTE=` — is appended under it, never in its place.
   - **The default is composed in the lane, never in `release_ios.sh`.** The build number is settled at step 2, inside the lane; the shell's `pubspec.yaml` still holds the old one, so a note written before the lane names the wrong build.
   - **The note is the design system's, not this app's.** `packages/script-tools/flutter/fastlane/Fastfile`, imported by `ios/fastlane/Fastfile`, owns `sd_release_note` and `sd_upload_to_testflight`, so every app on this tooling writes the same `<env> - <version name> (<version number>)`. The lane hands over flavour, version and settled build number — never a finished string.
   - **The note goes as `localized_build_info`, never `changelog`.** Both reach the same field, but `changelog` only PATCHES build localizations that already exist — a fresh upload has none, so every note sent that way was silently dropped, builds 2 to 10 included. Naming the locale makes pilot create the localization.
   - **The wait is the price, paid every release.** App Store Connect takes a note only after processing, so `skip_waiting_for_build_processing` is off — nothing else in the lane reads the result, and macOS minutes bill at 10x.
6. dSYMs, best effort — the build is already up; a symbol failure must not take the build-number commit down.
7. **Commit the build number, after the upload.** A bump commit with no build is a gap in the numbering; a build whose number is in no commit is what this order prevents.
   - **The lane commits and pushes, and only on CI** (`bump && is_ci`). The workflow has no push step of its own. A local `bump:true` run rewrites `pubspec.yaml` and leaves it for you — `release_ios.sh` says so at the end.
   - **The design system's gitlink goes in the same commit**, with its short sha and subject in the message. The workflow follows the submodule's `main`, not the commit the parent pins, so without that line the IPA on TestFlight would hold UI the app repo never recorded.

`make pre-build` is the `preflight` lane — everything a release needs but the build, three minutes instead of twenty-eight, and every credential failure ever seen surfaces in it. **`release-ios-*` does not run it**: run it by hand before a release. **`flavor:` is optional there and skipped, not defaulted**: defaulting to prod would fail a dev-machine rehearsal over the one question it was not asked.

`certificates` is **local only**, because CI runs `match(readonly: true)`: a runner that can mint distribution certificates burns Apple's limit of three, one failed job at a time. `force:true` regenerates the *profiles*, not the certificate, and is the only way a newly enabled capability reaches CI — otherwise `match` reuses the existing profile, the trap behind every "profile doesn't include the … entitlement".

## Four subtleties that cost real time

- **`runner?` is not `is_ci`.** `is_ci` is true on a Mac rehearsing with `CI=true` — exactly what this file says to run — and `setup_ci` there creates a throwaway keychain, adds it to the search list, and never removes it. The shared certificate then lives in two keychains and `codesign` starts prompting at `exportArchive`, after the whole build. Gate `setup_ci` on the CI provider's own variable.
- **Multi-target export.** `flutter build ipa --export-method` writes an `ExportOptions.plist` mapping only the main bundle id — its own source calls multi-target apps a TODO. Automatic signing hides it; with manual signing an extension gets no profile and `exportArchive` fails after the full build. The lane writes the plist itself with every id, and `packages/script-tools/flutter/build_ipa.sh` drops its own `--export-method` when a caller passes one. **One target today. Adding an extension means adding it to `sd_ios_app` in `ios/fastlane/Fastfile` and to the Matchfile** — the lane builds the plist from that list — and nothing will remind you.
- **An unreachable github.com is an SPM failure, not a build failure.** Every Swift package resolves from GitHub at the start of the archive; with no route, xcodebuild prints `Couldn't fetch updates from remote repositories:` with the reason on the next line, which flutter drops. Forty seconds, no cause named. `packages/script-tools/flutter/build_ipa.sh` checks reachability first and says so in ten. Nothing in the tree fixes it: connect a VPN and release again.
- **Delete the empty auth variable.** Actions sets every `${{ secrets.X }}` a workflow names, empty strings included, and `match` reads *both* auth variables from the environment whatever the call site passes — giving `remote: Duplicate header: "Authorization"`. Choosing one in code is not enough; the empty one must leave `ENV`.

## The workflow

**Manual `workflow_dispatch` only** — a release is an act, not a side effect of a push. Load-bearing in `.github/workflows/release.yml`:

- **`case`, never a `${{ a && b || c }}` ternary**, to pick the flavour's secret. The ternary falls to its second branch when the first secret is merely *empty* — silently building prod with dev config.
- **`plutil -lint` right after decoding the plist.** Otherwise a truncated paste looks like a good one until it throws on a device.
- **The URL scheme is derived from the plist just written**, not carried as a third secret.
- **Pin Ruby, then `bundle install`, in that order.** A gem binary runs only under the Ruby it was installed for.
- **`LANG` on the whole job**, or Ruby reads files as ASCII-8BIT and dies inside its own error reporter instead of on the failing line.
- **Free-text notes travel as an environment variable, never a lane argument**: spaces split into extra fastlane arguments and a backtick would execute.
- **The IPA is uploaded as an artifact.** If TestFlight later rejects the binary, the exact one sent is still there.

`docs/release/PIPELINE.md` is the shape of a run; `docs/release/CREDENTIALS.md` is what each credential is and where it lives. Everything not yet configured is in `docs/release/RELEASE_ACTIONS.md` — the one place "it doesn't work" is answered; this pipeline did not get a second.
