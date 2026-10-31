# Remaining work

Product and engineering work only; account, credential and store tasks are in [`RELEASE_ACTIONS.md`](../release/RELEASE_ACTIONS.md).

## Priority

| Priority | Work | Why |
|---|---|---|
| 1 | Deploy and verify Cloud Functions | Team, notifications, deletion and server-side entitlement need them |
| 2 | Move strings still hardcoded in Dart into ARB | Seven locales ship; those strings stay English in all of them |
| 3 | Add listing templates | Waits for a listing editor — no screen edits a listing's description yet |
| 4 | Dropshipping, with marketplace and supplier connections | Owner widened the product (`CLAUDE.md`); planned whole in `docs/plans/DROPSHIPPING_PLAN.md` first |
| 5 | Lock-screen actions for offers | An offer expires in hours; answering needs iOS notification categories, matching Android actions and an FCM payload change — none testable without a device |

## Open verification

| Item | Now | Done when |
|---|---|---|
| Apple/Google brand artwork | Placeholder glyphs | Approved vendor assets ship together |
| RevenueCat | Client and webhook code exist | Store products, entitlement, offering and webhook work end to end |
| Push notifications | Code exists | APNs registration, delivery and tap pass on hardware |
| Deep links | Registered on both platforms | A real notification opens the expected workspace and record |
| Mock data in release | Behind dev flags | Tree-shaking confirmed before submission |
| Free ceilings in production | Rules and triggers tested on the emulator | `onItemUsageWritten` and `onOrderUsageWritten` deployed; `usage/current` appears |
| Design-system CI source | CI follows remote `main` | Decide whether CI tests the pinned gitlink |

## Deferred or dropped

| Item | Decision |
|---|---|
| Vietnamese picker | Deferred until the full translation and review pass |
| v2 collapsing chrome | Not ported; v3 has a different screen model |

## Decided, built, worth watching

Owner decisions taken after the fact; the reasoning lives in `lib/features/orders/CLAUDE.md` (bundles) and `docs/rules/SUBSCRIPTION.md` (plan change).

| Decision | Watch |
|---|---|
| An order may name several items | Lines tied to no item are unbuilt and still need raising. `BundleAllocation` judges a bundle's split — watch whether sellers disagree often enough to want to edit a line. |
| Everything free except export | Free has no ceiling on items, orders, businesses or seats; payout chasing is free. Revert with `PlanLimits.byPlan` and its mirror in `functions/src/lib/firestore.ts`. Watch conversion: export at tax time is now the only reason to pay. |

Keep in step with [`DONE_WORK.md`](DONE_WORK.md).
