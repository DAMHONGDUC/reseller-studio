# Privacy and security — what must never enter a transcript

Read before opening any file that might hold a key, and before writing anything that logs, exports or uploads.

## Never read these paths

Not with Read, `cat`, `grep`, `sed` or `head`, not "just one field", not to check a key is set. **The harm is the copy landing in a transcript, not its size.**

```text
env/dev.json
env/prod.json
env_assets/**
ios/Runner/GoogleService-Info.plist
android/app/google-services.json
lib/firebase_options.dart
.firebaserc
functions/.env*
**/*.p8   **/*.p12   **/*.keystore   **/*.jks
```

**`env_assets/` is listed because it holds the same values one step upstream.** It was added after an agent listed the keys of `env_assets/dev.json`, then printed both flavours' files in full while tidying templates. The list named `env/*.json` but not their source copies, so the whole discipline was worth nothing. A value blocked here is blocked wherever else it lives.

**A script may read one; you may not print one.** `packages/script-tools/flutter/prepare_env.sh` copies these files — fine, and why it says it copies bytes and never reads them. The line is the transcript: any command whose output holds a value from these files has already done the harm — `cat`, `git diff`, `PlistBuddy Print`, or a Python script echoing what it wrote. Redirect to the file, never to stdout.

- **Which** keys exist: `env/env.example.json` — checked in, the key list, no values.
- **How** a key is used: `lib/core/config/app_env.dart`, the only file allowed to name one.

**This does not contradict "nothing in `env/` is secret"** (root `CLAUDE.md`, "Configuration and secrets"). Both hold; they answer different questions:

- *Is a leaked `env/dev.json` a breach?* No. `--dart-define-from-file` compiles those values into the binary, so anyone with the `.ipa` has them. They are public identifiers protected by `firestore.rules`.
- *Should the agent read one anyway?* No. No task needs the value, `prod.json` is the file most likely to gain something sensitive later, and a transcript is forwarded, pasted and archived far outside the repo.

The real secrets — marketplace OAuth secrets — are not here at all: they live in Secret Manager, read only by Cloud Functions (hard rule 10). `test/core/config/app_env_test.dart` fails any env key whose name contains `SECRET` or `PRIVATE`, so the discipline is enforced, not trusted.

## Nothing about prod is ever read

Owner's rule, wider than the path list: **nothing belonging to the production flavour is opened, printed or inspected** — not its config, its data, or the output of a command that names either. The list above guards values; this guards a whole environment, because only in prod does a mistake hit real sellers with no undo.

Blocked, whatever the tool:

```text
env/prod.json                    env_assets/prod.json
env_assets/prod-*                .firebaserc
```

…plus everything the prod Firebase project holds — Firestore documents, Storage objects, function logs, the console — and every release credential, since they exist to reach prod: `ios/fastlane/.env*`, the App Store Connect key, the match passphrase.

**Still allowed — the rule is unworkable without them:**

- `env/env.example.json` — checked in, placeholders only, the answer to "which keys does a build have?". `test/core/config/app_env_test.dart` reads it on purpose; it is the one file under `env/` a session may open.
- `lib/core/config/app_env.dart` — how a key is *used*.
- `make env-prod` and the release scripts. They **copy** prod files and never echo them; the read/print line above still applies. Running one is not reading one.

**The owner diagnoses a prod-only problem, not the agent.** Write the command, say what to look for, and ask for the *shape* of the answer — the error code, the count, which branch ran. Never the values.

## Never log a credential

Hard rule 9 in root `CLAUDE.md`, repeated here because this is the file people read when thinking about it:

- No password, OAuth token, API key, session cookie or buyer address.
- `SdLogger.error` reports to Crashlytics in release, so a log line is the shortest path from this code to a third-party dashboard.
- Log the **shape** of a failure — `'marketplace token refresh failed'`, the key name, the count, the collection — never the contents.
- `SdCrashReporter.setUserId` takes a Firebase UID and nothing else.
- `SdLogger.action`, `info` and `warning` leave a Crashlytics breadcrumb in every build — tag and message, never the data argument. So **a value goes in the data argument, never in the message string**: an interpolated message leaves the device; its data does not.

## Buyer data

An order may hold a real person's name — `Order.buyerName`, optional — the only personal data here that is not the seller's own. No order stores a shipping address.

- The name renders on screen and is stored in Firestore. Nowhere else.
- Never in a log line, analytics parameter, Crashlytics key, CSV filename, or committed test fixture.
- So `AppAnalytics` takes no free-text parameter: every event parameter is an id, an enum or a count.
- **A buyer address read from a connected marketplace passes through and is never stored.** Owner's call. The Function placing a supplier order reads it then, hands it to the supplier, keeps nothing — no Firestore field, log line or retry payload. The accepted cost: an order with no connection is never placed automatically, and a supplier refusing the address fails the order for the seller to fix on the marketplace.

## The `app_config` email lists

`app_config/current` holds three address lists — `premium_emails`, `dev_mode_emails`, `blocked_emails` — and **every signed-in account can read all three**: the rule allows any signed-in read, a rule cannot filter fields, and a client must check its own address.

- Treat anything in them as public to your users. The block list is the awkward one: it names people you refused.
- `AppConfig.toLogData` carries **counts, never addresses** — hard rule 9 applied to someone else's email.
- Anything that must stay private is done in the Firebase console: disabling an account is the real block. `docs/rules/DECISIONS.md` § The block list is a UI gate has the alternative and why.

## Before anything leaves the app

Exports and shares are the other way data escapes. `reports/` writes CSV to a temp file and hands it to the system share sheet: that file inherits every rule above, and it is the seller's own data going where the seller chose. Never add an upload, webhook or crash attachment carrying record contents without asking first.
