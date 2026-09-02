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

## Decided, built, and worth watching

Both were owner decisions taken after the fact rather than defaults, so the
reasoning lives where the next session will look: bundles in
`lib/features/orders/CLAUDE.md`, the plan change in
`docs/rules/SUBSCRIPTION.md`.

| Decision | What to watch |
|---|---|
| An order may name several items | Lines that belong to no item are still unbuilt and still need raising. A bundle's split is a judgement `BundleAllocation` makes, so watch whether sellers disagree with it often enough to want to edit a line. |
| Free counts no records; Premium sells capabilities | Reverting is one line in `PlanLimits.byPlan` plus its mirror in `functions/src/lib/firestore.ts`. Watch conversion: the argument is that a seller now reaches the tax and payout moments at all, and those are what the paywall is now sold on. |

Keep this file synchronized with [`DONE_WORK.md`](DONE_WORK.md).
