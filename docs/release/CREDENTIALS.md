# Release credentials

Never place credential values in this document.

## Local

| Location | Purpose |
|---|---|
| `ios/fastlane/.env` | App Store Connect and Match configuration |
| `env_assets/` | Per-flavor Firebase and build configuration source files |
| External `.p8` file | App Store Connect private key |
| Private certificates repo | Match-managed signing certificate and profile |

`ios/fastlane/.env.example` is the key list. Keep the real file gitignored and
newline-terminated.

## GitHub Actions secrets

| Secret | Format | Purpose |
|---|---|---|
| `ENV_DEV_JSON`, `ENV_PROD_JSON` | File content | Build-time configuration |
| `GOOGLE_SERVICE_INFO_PLIST_DEV`, `GOOGLE_SERVICE_INFO_PLIST_PROD` | Base64 | iOS Firebase configuration |
| `ASC_KEY_ID`, `ASC_ISSUER_ID` | Plain | App Store Connect API identity |
| `ASC_KEY_CONTENT` | Base64 | App Store Connect `.p8` |
| `MATCH_PASSWORD`, `MATCH_GIT_URL` | Plain | Signing repository access |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64 `user:PAT` | Read-only repository authorization |
| `FIREBASE_APP_ID_IOS` | Plain, optional | Crashlytics dSYM upload |

Set exactly one Match authorization mechanism. Two authorization headers make
Git reject the request.

## Rotation

| Credential | Impact | Recovery |
|---|---|---|
| App Store Connect key | Authenticated Fastlane steps fail | Create a key and update local/Actions values |
| Certificates-repo PAT | Match cannot clone | Create a repo-scoped read-only PAT |
| `MATCH_PASSWORD` | Match cannot decrypt | Reissue signing material and update every machine |
| Distribution certificate | Archive export fails | Run `bundle exec fastlane certificates` on a Mac |

Build-time fields compiled into the app are not secrets. Backend OAuth secrets
and webhook tokens belong in Secret Manager, never in Flutter configuration.
