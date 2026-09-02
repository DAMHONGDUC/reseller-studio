# Remaining work

Account, credential and store tasks live in
[`../RELEASE_ACTIONS.md`](../RELEASE_ACTIONS.md). This file tracks product and
engineering work only.

## Priority

| Priority | Work | Why |
|---|---|---|
| 1 | Deploy and verify Cloud Functions | Team, notifications, deletion and server-side entitlement depend on them |
| 2 | Complete the Vietnamese ARB pass | Only English ships until the locale is complete |
| 3 | Add listing templates | Last unbuilt listing workflow from plan §12 |
| 4 | Lock-screen actions for offers | An offer expires in hours; answering needs iOS notification categories, matching Android actions and an FCM payload change, none verifiable without a device |

## Open verification

| Item | Current state | Done when |
|---|---|---|
| Apple/Google brand artwork | Placeholder glyphs render | Approved vendor assets ship together |
| RevenueCat | Client and webhook code exist | Store products, entitlement, offering and webhook work end to end |
| Push notifications | Code exists | APNs registration, delivery and tap pass on hardware |
| Deep links | Registered on both platforms | Real notification opens the expected workspace and record |
| Mock data in release | Guarded by dev flags | Confirm tree-shaking before submission |
| Free ceilings in production | Rules and triggers written and tested against the emulator | `onItemUsageWritten` and `onOrderUsageWritten` are deployed and `usage/current` appears |
| Design-system CI source | CI follows remote `main` | Decide whether CI should test the pinned gitlink |

## Deliberately deferred or dropped

| Item | Decision |
|---|---|
| Vietnamese picker | Deferred until the full translation and review pass |
| Marketplace OAuth and publishing | Dropped; listings remain seller-maintained records |
| v2 collapsing chrome | Not ported; v3 owns a different screen model |

## Waiting on an owner decision

Neither is blocked on engineering. Both change something the owner has already
decided, so neither was built.

| Question | What it would change |
|---|---|
| Should an order be allowed more than one line? | Bundles are everyday on Poshmark and Depop, and splitting one into several orders destroys the per-item ROI Sourcing exists to measure. `lib/features/orders/CLAUDE.md` says raise it first: it changes the entity, every screen that taps through to an item, and what profit means for an order. The narrow version keeps `OrderLine.itemId` non-null and apportions the sale price by `expectedPrice`. |
| Should the Free ceiling stay a count of records? | `PlanLimits.byPlan` allows 50 items and 30 orders. The app's value only appears once the data is dense — sell-through, ROI by source, payout reconciliation and the tax pack are all meaningless at 40 items — so the ceiling blocks the process that creates the reason to pay. The alternative is to gate on outcomes instead: the tax pack, payout reconciliation, advanced analytics and team. `PlanFeature.requiredPlan` is already the single place that decides. |

Keep this file synchronized with [`DONE_WORK.md`](DONE_WORK.md).
