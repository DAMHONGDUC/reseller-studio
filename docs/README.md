# Documentation

Use the smallest document that answers the question. Authority documents are
intentionally detailed; operational documents are short checklists.

## Product and status

| Question | Document |
|---|---|
| What should the product do? | [`../SELLER_OS_FINAL_MASTER_PLAN.md`](../SELLER_OS_FINAL_MASTER_PLAN.md) |
| What is stored? | [`DATA_MODEL.md`](DATA_MODEL.md) |
| What is built? | [`DONE_WORK.md`](DONE_WORK.md) |
| What remains? | [`REMAINING_WORK.md`](REMAINING_WORK.md) |
| What blocks release? | [`../RELEASE_ACTIONS.md`](../RELEASE_ACTIONS.md) |
| What do stores need for privacy? | [`STORE_PRIVACY.md`](STORE_PRIVACY.md) |
| What does the published privacy policy say? | [`PRIVACY_POLICY.json`](PRIVACY_POLICY.json) — the source copy, rendered by the website repo; `icon` is a path on that site |

## Engineering rules

Start with [`../AGENTS.md`](../AGENTS.md). Read one topic file only when its
trigger matches the work.

| Topic | Document |
|---|---|
| Backend and Firestore | [`rules/BACKEND.md`](rules/BACKEND.md) |
| Commands | [`rules/COMMANDS.md`](rules/COMMANDS.md) |
| Decisions and reversals | [`rules/DECISIONS.md`](rules/DECISIONS.md) |
| Design system | [`rules/DESIGN_SYSTEM.md`](rules/DESIGN_SYSTEM.md) |
| Build-time configuration | [`rules/ENV.md`](rules/ENV.md) |
| Privacy and secrets | [`rules/PRIVACY_AND_SECURITY.md`](rules/PRIVACY_AND_SECURITY.md) |
| Release | [`rules/RELEASE.md`](rules/RELEASE.md) |
| Screens | [`rules/SCREENS.md`](rules/SCREENS.md) |
| Missing setup | [`rules/SETUP.md`](rules/SETUP.md) |
| Premium and paywall | [`rules/SUBSCRIPTION.md`](rules/SUBSCRIPTION.md) |
| Tests | [`rules/TESTING.md`](rules/TESTING.md) |

## Release operations

| Need | Document |
|---|---|
| Credential names and locations | [`release/CREDENTIALS.md`](release/CREDENTIALS.md) |
| Release flow and failure lookup | [`release/PIPELINE.md`](release/PIPELINE.md) |
