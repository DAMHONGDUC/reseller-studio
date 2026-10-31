# Data model

Authority on what Firestore stores and what each field means. Product behavior is `docs/plans/SELLER_OS_FINAL_MASTER_PLAN.md`; access is `firestore.rules`.

**Before sign-in a second store holds these same records.** A guest's rows live in a local Drift database and drain into Firestore at sign-in (hard rule 1). It is not a second data model:

- every row is the **same DTO map** this file describes, JSON-encoded;
- so a field means the same in both, and a field added below needs nothing in the local schema;
- the local key, how the drain restamps a row, and why there are no sync columns: `docs/rules/GUEST_MODE.md`.

## Layout

```text
users/{uid}
  devices/{token}
  notifications/{notificationId}

invites/{inviteId}
app_config/current

workspaces/{workspaceId}

members/{workspaceId}_{uid}
sources/{workspaceId}_{sourceId}
purchases/{workspaceId}_{purchaseId}
items/{workspaceId}_{itemId}
listings/{workspaceId}_{listingId}
offers/{workspaceId}_{offerId}
orders/{workspaceId}_{orderId}
expenses/{workspaceId}_{expenseId}
receipts/{workspaceId}_{receiptId}
categories/{workspaceId}_{categoryId}
locations/{workspaceId}_{locationId}
marketplaces/{workspaceId}_{marketplaceId}
carriers/{workspaceId}_{carrierId}
activity/{workspaceId}_{activityId}

subscription/{workspaceId}
usage/{workspaceId}
```

**Every business table is flat and top-level, shaped like SQL** (hard rule 14). Each row has a `workspaceId` column and the key `{workspaceId}_{id}` — SQL's composite primary key. Without it every business's `ebay` marketplace, `usps` carrier and `{uid}` membership would be one row.

| | Enforced in |
|---|---|
| Every read filters on `workspaceId` | `WorkspaceTable.query` — no accessor returns an unfiltered collection |
| Every write stamps `workspaceId` | The converter in `WorkspaceCollections._table`, so no DTO carries the column |
| A row cannot move between businesses | `canUpdateRow()` in `firestore.rules` compares stored and incoming column |
| An unfiltered query is denied, not leaked | A `list` rule runs per row; foreign rows fail it and fail the query |
| Deleting a business sweeps every table | `WorkspaceCollections.tableNames` / `workspaceTables` in `functions/` |

- `subscription` and `usage` are keyed by the workspace id alone: one row each per business, so the id *is* the key.
- `users/{uid}` keeps its two subcollections: they belong to a person, not a business, and a device token addresses whoever holds the phone.
- **Migration is `functions/src/scripts/flattenTables.ts`**: it copies every nested record into its flat table and sweeps originals only when told, so a half-finished run loses nothing.

## Shared contracts

| Rule | Contract |
|---|---|
| Identity | Document ID is the identity; no duplicate `id` field |
| Audit fields | Business records carry `createdAt`, `updatedAt`, `createdBy` |
| Timestamps | Server timestamps for persisted audit fields |
| Money | Integer minor units; field names end in `Minor` |
| Currency | Stored beside money, or inherited from the workspace |
| Missing money | `null` means unknown, not zero |
| Derived finance | Never store profit, margin or ROI — never estimate a fee |
| Payout exception | `orders.payoutMinor` is stored: a reported fact |
| Platform fee | Derived: `salePrice - refund - payout - shippingCost`; null until a payout is recorded |
| Planning rate | `workspaces/{id}.planningFeeRate` — one assumption for Sourcing, never written to an order |
| Deletion | Referenced records soft-delete with `deletedAt` |

## Relationships

```text
Source ──< Purchase ──< Item ──< Listing ──< Offer
                                   │
                                   └──< Order ──> derived Profit
```

Child references are nullable. Quick Add creates an item from a title alone; the chain serves workflows and analytics, not item validity.

## Collections

| Path | Main fields | Contract |
|---|---|---|
| `users/{uid}` | `displayName`, `email`, `avatarUrl`, `locale`, `lastWorkspaceId`, `workspaceIds`, `notificationPrefs` | Person and workspace pointers only; no business records |
| `users/{uid}/devices/{token}` | `token`, `platform`, `updatedAt` | Token is also the document ID; never log it |
| `users/{uid}/notifications/{id}` | `type`, `workspaceId`, `entityId`, `count`, `route`, `title`, `body`, `readAt`, `createdAt` | Functions create; client updates only `readAt`; ID is the dedupe key |
| `invites/{id}` | Invitee email, workspace, role, status, timestamps | Functions write; invitee access is rule-scoped |
| `workspaces/{id}` | `name`, `ownerId`, `country`, `currency`, `timezone`, `businessType`, `logoUrl` | Required at creation: name, country, currency |
| `members/{uid}` | `role`, `displayName`, `email`, `joinedAt` | Membership is the only ACL; identity denormalized for safe team reads |
| `sources/{id}` | Source details, `type` (`dropshipSupplier` for a dropship supplier), address, `deletedAt` | Soft-delete: purchases reference sources |
| `purchases/{id}` | Source, date, costs, receipt links, `deletedAt` | Parent of acquired items |
| `items/{id}` | Title, quantity, status, `fulfilment` (`stocked` or `dropship`), pricing, purchase/source/category/location fields, `listedAt`, `deletedAt` | Status is `draft`, `inStock`, `sold` or `archived`; stale is a query, not a status |
| `categories/{id}` | `name`, `parentId`, `description`, `deletedAt` | Seller-owned hierarchy, editable defaults |
| `locations/{id}` | Warehouse/shelf/bin identity, `deletedAt` | Seller-owned storage hierarchy |
| `listings/{id}` | Item, `marketplaceId` + `marketplaceName`, price, status, external IDs/URL | One per item per marketplace; the marketplace is the seller's own record, not a fixed platform; external fields stay null without integration |
| `offers/{id}` | Listing/order references, `marketplaceId` + `marketplaceName`, amount, status, timestamps | State drives accept/decline/counter; marketplace is the seller's record, as on a listing |
| `marketplaces/{id}` | `name`, `hue`, `deletedAt` | Seller-owned; no fee rate — a platform's cut is measured per order |
| `carriers/{id}` | `name`, `deletedAt` | Business-owned shipping choices |
| `pricing_rules/{id}` | `name`, `scope`, `scopeId`, `multiplier`, `currency`, `fixedAddMinor`, `rounding`, `minProfitMinor`, `deletedAt` | How a cost becomes an asking price; config, never a stored sale figure (hard rule 3). Soft-deleted: price history names rules |
| `listing_price_changes/{id}` | `listingId`, `itemId`, `currency`, `fromMinor`, `toMinor`, `reason`, `ruleId`, `createdAt` | One row per price move, same batch as the listing; create-only |
| `supplier_products/{id}` | `sourceId`, `title`, `itemId`, `rank`, `url`, `externalProductId`, `externalVariantId`, `currency`, `supplierPriceMinor`, `supplierShippingMinor`, `supplierTaxMinor`, `shippingDays`, `stock`, `lastCheckedAt`, `deletedAt` | One supplier variant; `itemId` + `rank` name the item it stocks and its preference order. Soft-deleted: supplier orders name it |
| `supplier_orders/{id}` | `sourceId`, `status`, `orderId`, `itemId`, `supplierProductId`, `externalSupplierOrderId`, `currency`, `productCostMinor`, `shippingCostMinor`, `taxMinor`, `supplierRefundMinor`, `isSample`, `trackingNumber`, `carrier`, `placedAt`, `shippedAt`, `deliveredAt`, `failureCode`, `invoiceUrl` | One order with a dropship supplier for one sold line. Its net cost goes onto that line's `unitCost` in the same commit; "to order" is a query, never a status |
| `orders/{id}` | Prices/costs, status, marketplace snapshot, lifecycle timestamps, `lines` | Order facts plus embedded, immutable sale-time lines |
| `expenses/{id}` | Category, amount, date, recurrence link, `supplierOrderId` for a dropship sample | One document per occurrence |
| `receipts/{id}` | File metadata, parent reference | Metadata in Firestore; file in Storage |
| `activity/{id}` | `entityType`, `entityId`, `action`, `actorId`, `before`, `after`, `createdAt` | Append-only, Functions-written |
| `subscription/{id}` | Plan/entitlement state, timestamps | Webhook-written; backend source for Premium enforcement |
| `usage/current` | `items`, `orders`, `itemsAtCeiling`, `ordersAtCeiling` | Trigger-written; the only thing `firestore.rules` can read to enforce a Free ceiling — a rule cannot count a collection. `items` counts every row created and kept; `orders` only the last 30 days, so a scheduled recount clears a window that emptied with no write |

## Snapshots and denormalization

| Field | Why copied |
|---|---|
| Item `purchaseDate`, `sourceId` | Firestore cannot sort/filter through a referenced purchase |
| Member `displayName`, `email` | Team cannot read another user's private profile |
| Order `marketplaceName` | A marketplace rename/delete must not rewrite sale history |
| Listing `marketplaceName` | Same, for what was posted: the name the platform had when it went up |
| Offer `marketplaceName` | Same, for an offer: the name its platform had when it arrived |
| Item `purchaseId` | Sourcing joins a receipt to what it bought; apportioning writes each item's share |
| Order line title, price, cost | Repricing an item must not rewrite a sale |
| Notification `title`, `body` | Push needs text; the inbox renders from `type` and `count` |

## Notification preferences

`users/{uid}.notificationPrefs` maps a `NotificationType` name to whether it is wanted.

- **Only mutes are stored**: an absent key is on, so a type added later arrives on, not silently off for everyone who upgraded.
- It hangs off the person, not the workspace: two people sharing a business want different reminders.
- **A mute silences the push only** — `notifyWorkspace` still writes the inbox row. The row is the notification; the push is a copy.

## Order contract

| Group | Fields |
|---|---|
| Money | `salePriceMinor`, `shippingCostMinor`, `refundMinor`, `payoutMinor` (a legacy `feesMinor` reads back as the payout it implies) |
| Marketplace | `marketplaceId`, `marketplaceName`, `externalOrderId` |
| Lifecycle | `orderedAt`, `shipByDate`, `shippedAt`, `deliveredAt`, `returnRequestedAt`, `returnedAt`, `refundedAt`, `settledAt` |
| Lines | `{itemId, title, quantity, unitPriceMinor, unitCostMinor}` |

Lifecycle timestamps stay facts after status changes. Lines are embedded: small, always read with the order, immutable after sale.

## App config

`app_config/current` is one document for the whole product, read by every client, written by none.

- **It is not a business record**, so it sits under no workspace: nothing in it is a seller's, and two businesses on one build read the same answer.
- **It is the one public read in `firestore.rules`**: the forced update is read before sign-in. So the three email lists below are world-readable — that limits what may go here (`docs/rules/BACKEND.md`).

| Field | Type | Meaning |
|---|---|---|
| `force_update` | map | One block per store — `ios` and `android` |
| `premium_emails` | string[] | Accounts given Premium without buying it |
| `dev_mode_emails` | string[] | Accounts with developer affordances in a release build |
| `blocked_emails` | string[] | Accounts refused the app |
| `error_view` | map | A screen shown in place of the whole app |

## The error view

`error_view` is the owner's remote notice: a screen the app shows instead of itself, for the hour between a problem and the release that fixes it — a migration, an outage, a marketplace that stopped answering. The seller reads a sentence someone wrote, not five tabs of quietly wrong numbers.

| Field | Type | Meaning |
|---|---|---|
| `enable` | bool | The switch. Anything but `true` leaves the app running |
| `title` | string | Read first. **Empty shows nothing, switch or not** |
| `subtitle_1` | string | What it means for the seller |
| `subtitle_2` | string | A quieter second line — what to do, or when to return. Empty draws no row |
| `type` | string | `warning` or `error`. Anything else reads as `error` |

- **Not about an account.** No email is matched, no seller exempt: every client on every build shows it — like a forced update, it targets the binary, not the person.
- **The most dangerous field here; every default reflects that.** A mistake blanks the app for everyone, with no way to ship them out. A missing block, a wrong-typed block, a non-bool switch or a non-string title all mean *show nothing*. Only `true` plus a non-empty title shows a screen; `AppErrorNotice.shows` asks both, once.
- **A switch with no title shows nothing, on purpose.** A notice with no words is a screen with no way out — worse than the state it explains.
- **Its words are world-readable**, like the whole document — no cost here, they are written for every seller. What may be added is still `docs/rules/BACKEND.md`.
- **It outranks the forced update.** `ErrorNoticeGate` sits above `ForceUpdateGate` and replaces its child, so with a notice up the router is never built.

## The forced update

`force_update` holds one block per store, `ios` and `android`, each with the same four fields.

- Nested under one field, not loose at top level: top-level `ios`/`android` reads as config *about platforms*, when it is one feature configured per store.
- One block per store because the stores never align: build `41` on the App Store and on Google Play are different binaries reviewed at different times. One ceiling would block a shipped release or let an old one through. The app reads its own platform's block only.

| Field | Type | Meaning |
|---|---|---|
| `enable_force_update` | bool | Master switch for this store |
| `build_number` | int | The store's build — the `+41` of `1.4.0+41` |
| `build_name` | string | The version the seller recognises. Shown, never compared |
| `store_link` | string | Where the seller goes to update |

- **The switch is checked before the number — that is why both exist.** The owner keeps `build_number` current routinely and turns `enable_force_update` on once, when a build truly cannot keep running. Raising the build alone forces nothing.
- **A build number, never a version string**: the stores already order by this monotonic integer, so the check is `<` alone. `1.10.0` vs `1.9.0` is exactly where a hand-written semver comparator fails. `build_name` is display only; the app never parses it.
- `store_link` is configured, not compiled in: a broken link must be fixable without a release — the one thing a forced-update prompt cannot ask for. Null draws no button rather than a dead one.
- **The UI is an undismissable bottom sheet, not a route.** `ForceUpdateGate` wraps the app and draws over whatever is on screen: no `/update-required` path, no redirect, no modal route, no back stack to unwind when config is fixed. Why: `docs/rules/DECISIONS.md` § The forced update is a sheet.

**A missing document, missing field, mistyped value or failed read all resolve to `AppConfig.fallback`.** The document is hand-edited, so a typo is the likely failure; each field falls back the safe way:

| Field | Falls back to | Why |
|---|---|---|
| `force_update` | Forcing nothing | A wrong answer locks every seller out of an app they cannot fix, with no way to ship them out |
| Every email list | Empty | Nobody is refused over a failed read; nobody gets a grant the owner did not type |

The forced-update and blocked gates have **no loading state**: until an answer arrives the build counts as new enough and the account as allowed, so neither check can stop the app starting. A build the platform plugin cannot name counts as newer than any ceiling, for the same reason.

## The three email lists

Each is an array of plain addresses, **lowercased and trimmed on read**: the document is hand-typed, so ` Owner@Gmail.com ` is a normal correct entry and a case-sensitive match would silently hit nobody. Anything but a list of non-empty strings reads as no entries.

| List | Effect | Where |
|---|---|---|
| `premium_emails` | `currentPlanProvider` answers Premium; every ceiling and capability opens | `premiumGrantedByEmailProvider` |
| `dev_mode_emails` | More's dev rows, mock data and demo seed appear in a **release** build | `devModeEnabledProvider` |
| `blocked_emails` | The account goes to `/blocked` and can only sign out | `accountBlockedProvider` |

- `premium_emails` is a **grant, never a purchase record**: the `subscription` row stays the true answer to what the seller bought, and a screen showing that reads the row.
- `dev_mode_emails` broke an old guarantee: a `const` used to tree-shake the mock branch out of release binaries; now it ships, because an email list is a release-build grant by definition. See `docs/rules/DECISIONS.md` § Dev mode is granted by email.
- `blocked_emails` is a **UI gate, not a permission**. A blocked account still holds a valid token; `firestore.rules` does not know the list. Anything that must be refused is refused there, or by disabling the account in the Firebase console.
- **Every signed-in account can read all three**: the rule allows any signed-in read, a rule cannot filter fields, and a client must check its own address. Keep the lists short and nothing in them that must stay private — `docs/rules/DECISIONS.md` § The block list is a UI gate has the reasoning and the alternative.

`firestore.rules` allows any signed-in read and no write — a client that could write this could switch off its own paywall.

The whole document, every field filled in:

```json
{
  "force_update": {
    "ios": {
      "store_link": "https://apps.apple.com/app/id0000000000",
      "build_name": "1.4.0",
      "build_number": 41,
      "enable_force_update": false
    },
    "android": {
      "store_link": "https://play.google.com/store/apps/details?id=com.example.app",
      "build_name": "1.4.0",
      "build_number": 41,
      "enable_force_update": false
    }
  },
  "premium_emails": ["owner@example.com", "tester@example.com"],
  "dev_mode_emails": ["owner@example.com"],
  "blocked_emails": ["banned@example.com"]
}
```

Every field is optional; an absent one reads as its fallback, so the smallest useful document is one key. The same document is `sample_data/app_config/current.json` — copy it when creating the document in the console.

## Indexes

`firestore.indexes.json` is the index authority. Add an index in the same change as the query that needs it.
