# Credentials

What each one is, where it lives, and what it can do. **No value appears in
this file and none ever should** — hard rule 9 applies to a document as much as
to a log line.

## Local — `ios/fastlane/.env`

Gitignored. `ios/fastlane/.env.example` is the committed key list. Check the
shape without reading a value:

```bash
cut -d= -f1 ios/fastlane/.env
```

| Key | What it is |
|---|---|
| `ASC_KEY_ID` | App Store Connect API key id. |
| `ASC_ISSUER_ID` | The issuer that key belongs to. |
| `ASC_KEY_FILEPATH` | Path to the `.p8`. Keep it outside the repo; `ios/fastlane/*.p8` is gitignored as a second line of defence. |
| `MATCH_PASSWORD` | Decrypts the certificates repo. Losing it means revoking the certificate and starting over. |
| `MATCH_GIT_URL` | The private certificates repo. |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `base64` of `user:PAT` for that repo. |

**The file must end with a newline.** `>>` appends bytes, not lines, so a
missing one turns the next appended variable into a suffix of the previous
value — and the symptom is "the previous variable is nonsense", not "variable
missing".

## Local — `env_assets/`

Gitignored. Your own copy of every per-project file, one set per flavour; see
`docs/rules/RELEASE.md`. Not secret in the sense `env/` is not secret — these
are public identifiers — but they *are* per-project, and the wrong one in the
wrong place is the failure mode the whole pipeline is built around.

## Actions secrets

| Secret | Encoding | Why |
|---|---|---|
| `ENV_DEV_JSON`, `ENV_PROD_JSON` | The whole file, verbatim | Adding a key later needs no workflow change. |
| `GOOGLE_SERVICE_INFO_PLIST_DEV`, `..._PROD` | base64 | Multi-line XML whose newlines must survive. |
| `ASC_KEY_ID`, `ASC_ISSUER_ID` | Plain | |
| `ASC_KEY_CONTENT` | base64 of the `.p8` | |
| `MATCH_PASSWORD`, `MATCH_GIT_URL` | Plain | |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 of `user:PAT` | **Set exactly one auth secret.** A `..._BEARER_AUTHORIZATION` variant takes the PAT verbatim. Both set, even with one empty, gives `Duplicate header: "Authorization"`. |
| `FIREBASE_APP_ID_IOS` | Plain, optional | Unset skips the dSYM upload with a warning. |

## The certificates repo

**Private, and separate from this one.** `match` stores a real distribution
certificate's private key in it, encrypted with `MATCH_PASSWORD`.

Its PAT is **fine-grained, that repo only, Contents: Read-only**. CI never
writes — `match(readonly: true)` — so a token that can write grants an ability
nothing uses.

## What is deliberately not a credential

- **Everything in `env/`.** `--dart-define-from-file` compiles the JSON into
  the binary; anyone with the `.ipa` can read it. See `docs/rules/ENV.md`.
- **The reversed client id.** Public, and derived at build time rather than
  stored (`tool/_url-scheme.sh`).
- **Marketplace OAuth secrets** — hard rule 10. Secret Manager, read by Cloud
  Functions, never by this pipeline.

## Rotating one

| Credential | What breaks while it is wrong | Fix |
|---|---|---|
| ASC API key | Every lane, at the first authenticated call | New key in App Store Connect, update `.env` and the two Actions secrets. |
| The PAT | `match`, cloning the certificates repo | New fine-grained PAT, re-base64 it. |
| `MATCH_PASSWORD` | `match`, decrypting | `match nuke` and re-issue. This revokes the certificate — every machine re-runs `certificates`. |
| The distribution certificate | `exportArchive` | `bundle exec fastlane certificates`, from a Mac. |
