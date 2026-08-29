# Privacy and security — what must never enter a transcript

Read this before opening any file that might carry a key, and before writing
anything that logs, exports or uploads.

## Never read these paths

Not with Read, not with `cat`, `grep`, `sed` or `head`, not "just one field",
not to check whether a key is set. **The harm is the copy landing in a
transcript, not the size of it.**

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

**`env_assets/` is on that list because it is the same values one step
upstream.** It was added after an agent listed the keys of `env_assets/dev.json`
and then printed both flavours' files in full while tidying the templates — the
list named `env/*.json`, the copies it is made from were not on it, and the
whole discipline was worth nothing. A path that holds a value blocked here is
blocked wherever else it lives.

**A script may read one; you may not print one.** `packages/system_design/tool/prepare-env.sh` copies
these files and `_url-scheme.sh` derives from one, which is fine and is why
`prepare-env.sh` says it copies bytes and never reads them. The line is the
transcript: a command whose output contains a value from one of these files has
already done the harm, whether it was `cat`, a `git diff`, a `PlistBuddy Print`
or a Python script echoing what it just wrote. Redirect to the file, never to
stdout.

To find out **which** keys exist, read `env/env.example.json` — it is checked
in, it is the key list, and it carries no values. To find out how a key is used,
read `lib/core/config/app_env.dart`, which is the only file allowed to name
one.

**This does not contradict "nothing in `env/` is secret"** (root `CLAUDE.md`,
"Configuration and secrets"). Both are true and they answer different
questions:

- *Is a leaked `env/dev.json` a breach?* No. `--dart-define-from-file` compiles
  those values into the binary, so anyone with the `.ipa` already has them.
  They are public identifiers protected by `firestore.rules`.
- *Should the agent read one anyway?* No. There is no task that needs the
  value, `prod.json` is the file most likely to gain something sensitive
  later, and a transcript is forwarded, pasted and archived in places the repo
  is not.

Marketplace OAuth secrets are the real ones, and they are not here at all —
they live in Secret Manager and are read only by Cloud Functions (hard rule
10). `test/core/config/app_env_test.dart` fails any env key whose name
contains `SECRET` or `PRIVATE`, so the discipline is enforced rather than
trusted.

## Nothing about prod is ever read

Owner's rule, and it is wider than the path list above: **anything belonging to
the production flavour is not opened, not printed, not inspected.** Not the
config, not the project's data, not the output of a command that would name
either. The list above is about values that must not reach a transcript; this
one is about a whole environment, because prod is the only one where a mistake
lands on real sellers and there is no undo.

Blocked, whatever the tool:

```text
env/prod.json                    env_assets/prod.json
env_assets/prod-*                .firebaserc
```

…and everything the prod Firebase project holds — Firestore documents, Storage
objects, function logs, the console. Also every release credential, since they
exist to reach prod: `ios/fastlane/.env*`, the App Store Connect key, the match
passphrase.

**Still allowed, and the rule would be unworkable without them:**

- `env/env.example.json` — checked in, placeholders only, and it is the
  answer to "which keys does a build have?". `test/core/config/app_env_test.dart`
  reads it, on purpose, and it is the single file under `env/` a session may
  open.
- `lib/core/config/app_env.dart`, which is how a key is *used*.
- `packages/system_design/tool/prepare-env.sh prod` and the release scripts. They **copy** prod files
  and never echo them — the read/print line above applies unchanged. Running
  one is not reading one.

**A prod-only problem is diagnosed by the owner, not by the agent.** Write the
command, say what to look for, and ask for the *shape* of the answer back — the
error code, the count, which branch it took. Never the values.

## Never log a credential

This is hard rule 9 in the root `CLAUDE.md` and it is repeated here because
this is the file people read when they are thinking about it:

- No password, OAuth token, API key, session cookie or buyer address.
- `SdLogger.error` reports to Crashlytics in release, so a log line is the
  shortest path from this codebase to a third-party dashboard.
- Log the **shape** of a failure — `'marketplace token refresh failed'`, the
  key name, the count, the collection — never the contents.
- `SdCrashReporter.setUserId` takes a Firebase UID and nothing else.

## Buyer data

An order carries a real person's name and shipping address. It is the only
personal data in this app that is not the seller's own.

- It renders on screen and it is stored in Firestore. It goes nowhere else.
- It must never appear in a log line, an analytics parameter, a Crashlytics
  key, a CSV filename, or a test fixture committed to the repo.
- `AppAnalytics` takes no free-text parameter for this reason — every event
  parameter is an id, an enum or a count.

## Before anything leaves the app

Exports and shares are the other way data escapes. `reports/` writes CSV to a
temp file and hands it to the system share sheet: that file inherits every
rule above, and it is the seller's own data going somewhere the seller chose.
Never add an upload, a webhook or a crash attachment that carries record
contents without asking first.
