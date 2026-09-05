# Data model

Authority for what Firestore stores and what each field means. Product behavior
belongs to `SELLER_OS_FINAL_MASTER_PLAN.md`; access belongs to
`firestore.rules`.

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

**Every business table is flat and top-level, modelled the way SQL would model
it** (hard rule 14). Each row carries a `workspaceId` column and is keyed by a
composite `{workspaceId}_{id}`, which is how SQL spells a composite primary
key — without it every business's `ebay` marketplace, `usps` carrier and
`{uid}` membership would be the same row.

| | Where it is enforced |
|---|---|
| Every read filters on `workspaceId` | `WorkspaceTable.query` — there is no accessor that returns an unfiltered collection |
| Every write stamps `workspaceId` | the converter in `WorkspaceCollections._table`, so no DTO carries the column |
| A row cannot be moved between businesses | `canUpdateRow()` in `firestore.rules` compares the stored column with the incoming one |
| An unfiltered query is denied, not leaked | a `list` rule runs per row, so foreign rows fail it and take the query down |
| Deleting a business sweeps every table | `WorkspaceCollections.tableNames` / `workspaceTables` in `functions/` |

`subscription` and `usage` are keyed by the workspace id alone: there is
exactly one row of each per business, so the id *is* the key.

`users/{uid}` keeps its two subcollections. They belong to a person rather than
a business, and a device token is addressed to whoever holds the phone.

**Migrating existing data is `functions/src/scripts/flattenTables.ts`** — it
copies every nested record into its flat table, and only sweeps the originals
when told to, so a half-finished run loses nothing.

## Shared contracts

| Rule | Contract |
|---|---|
| Identity | Document ID is the identity; do not store a duplicate `id` field |
| Audit fields | Business records carry `createdAt`, `updatedAt`, `createdBy` |
| Timestamps | Use server timestamps for persisted audit fields |
| Money | Integer minor units; field names end in `Minor` |
| Currency | Store beside money or inherit the workspace currency |
| Missing money | `null` means unknown; it is not zero |
| Derived finance | Never store profit, margin or ROI — and never estimate a fee |
| Payout exception | `orders.payoutMinor` is stored because it is a reported fact |
| Platform fee | Derived: `salePrice - refund - payout - shippingCost`; null until a payout is recorded |
| Planning rate | `workspaces/{id}.planningFeeRate` — one assumption for Sourcing, never written to an order |
| Deletion | Referenced records are soft-deleted with `deletedAt` |

## Relationships

```text
Source ──< Purchase ──< Item ──< Listing ──< Offer
                                   │
                                   └──< Order ──> derived Profit
```

Child references are nullable. Quick Add can create an item with only a title;
the relationship chain supports workflows and analytics, not item validity.

## Collections

| Path | Main fields | Contract |
|---|---|---|
| `users/{uid}` | `displayName`, `email`, `avatarUrl`, `locale`, `lastWorkspaceId`, `workspaceIds`, `notificationPrefs` | Person and workspace pointers only; no business records |
| `users/{uid}/devices/{token}` | `token`, `platform`, `updatedAt` | Token is also the document ID; never log it |
| `users/{uid}/notifications/{id}` | `type`, `workspaceId`, `entityId`, `count`, `route`, `title`, `body`, `readAt`, `createdAt` | Functions create; client may update only `readAt`; ID is the dedupe key |
| `invites/{id}` | Invitee email, workspace, role, status and timestamps | Functions own writes; invitee access is rule-scoped |
| `workspaces/{id}` | `name`, `ownerId`, `country`, `currency`, `timezone`, `businessType`, `logoUrl` | Required creation fields are name, country and currency |
| `members/{uid}` | `role`, `displayName`, `email`, `joinedAt` | Membership is the only ACL; identity is denormalized for safe team reads |
| `sources/{id}` | Source details, address, `deletedAt` | Soft-delete because purchases reference sources |
| `purchases/{id}` | Source, date, costs, receipt links, `deletedAt` | Parent of acquired items |
| `items/{id}` | Title, quantity, status, pricing, purchase/source/category/location fields, `listedAt`, `deletedAt` | Status is `draft`, `inStock`, `sold` or `archived`; stale is a query, not a status |
| `categories/{id}` | `name`, `parentId`, `description`, `deletedAt` | Seller-owned hierarchy with editable defaults |
| `locations/{id}` | Warehouse/shelf/bin identity and `deletedAt` | Seller-owned storage hierarchy |
| `listings/{id}` | Item, marketplace, price, status, external IDs/URL | One record per item per marketplace; external fields remain null without integration |
| `offers/{id}` | Listing/order references, amount, status and timestamps | Offer state drives accept/decline/counter workflows |
| `marketplaces/{id}` | `name`, `hue`, `deletedAt` | Seller-owned; carries no fee rate — a platform's cut is measured per order |
| `carriers/{id}` | `name`, `deletedAt` | Business-owned shipping choices |
| `orders/{id}` | Prices/costs, status, marketplace snapshot, lifecycle timestamps, `lines` | Order facts and embedded immutable sale-time lines |
| `expenses/{id}` | Category, amount, date, recurrence link | One document per occurrence |
| `receipts/{id}` | File metadata and parent reference | Metadata in Firestore; file in Storage |
| `activity/{id}` | `entityType`, `entityId`, `action`, `actorId`, `before`, `after`, `createdAt` | Append-only and Functions-written |
| `subscription/{id}` | Plan/entitlement state and timestamps | Webhook-written; backend source for Premium enforcement |
| `usage/current` | `items`, `orders`, `itemsAtCeiling`, `ordersAtCeiling` | Trigger-written; the only thing `firestore.rules` can read to enforce a Free ceiling, because a rule cannot count a collection |

## Important snapshots and denormalization

| Field | Why it is copied |
|---|---|
| Item `purchaseDate`, `sourceId` | Firestore cannot sort/filter through a referenced purchase |
| Member `displayName`, `email` | Team cannot read another user's private profile document |
| Order `marketplaceName` | Marketplace rename/delete must not rewrite sale history |
| Order line title, price and cost | Repricing an item must not rewrite an existing sale |
| Notification `title`, `body` | Push delivery needs text; the app renders inbox copy from `type` and `count` |

## Notification preferences

`users/{uid}.notificationPrefs` maps a `NotificationType` name to whether that
reminder is wanted. **Only the mutes are stored**: an absent key is on, so a
type added in a later build arrives switched on rather than silently off for
everyone who upgraded into it.

It hangs off the person rather than the workspace because two people sharing a
business do not want the same reminders. **A mute silences the push only** —
`notifyWorkspace` still writes the inbox row, because the row is the
notification and the push is a copy of it.

## Order contract

| Group | Fields |
|---|---|
| Money | `salePriceMinor`, `shippingCostMinor`, `refundMinor`, `payoutMinor` (a legacy `feesMinor` is read back as the payout it implies) |
| Marketplace | `marketplaceId`, `marketplaceName`, `externalOrderId` |
| Lifecycle | `orderedAt`, `shipByDate`, `shippedAt`, `deliveredAt`, `returnRequestedAt`, `returnedAt`, `refundedAt`, `settledAt` |
| Lines | `{itemId, title, quantity, unitPriceMinor, unitCostMinor}` |

Lifecycle timestamps remain facts even after status changes. Lines are embedded
because they are small, always read with the order, and immutable after sale.

## App config

`app_config/current` is one document for the whole product, read by every
client and written by none. **It is not a business record**, so it is not
nested under a workspace — nothing in it belongs to a seller, and two
businesses on the same build read the same answer.

| Field | Type | Meaning |
|---|---|---|
| `premium_enabled` | bool | Whether the plan system applies at all |
| `minimum_build` | int | The oldest build allowed to run |
| `update_url` | string | Where the forced-update screen sends the seller |

`premium_enabled: false` turns monetisation off for everyone: `currentPlanProvider`
answers Premium, so no ceiling blocks a create and every capability is
included, and the Subscription row and the Home upgrade banner are not drawn.

`minimum_build` is compared against the running build — the `+7` of `1.0.0+7`.
**A build number, never a version string**: it is the monotonic integer the
stores already order by, so the comparison is `<` and nothing else, where
`1.10.0` against `1.9.0` is exactly where a hand-written semver comparator is
wrong. Anything below it is sent to `/update-required` and cannot leave.
`update_url` is configured rather than compiled in, because a broken store
link must be fixable without shipping a release — which is the one thing a
forced-update screen cannot ask for.

**A missing document, a missing field, a mistyped value or a failed read all
resolve to `AppConfig.fallback`.** The document is edited by hand, so a typo
is the likely failure — and the two flags fall back in **opposite**
directions, each the safe one for what it controls:

| Flag | Falls back to | Why that way |
|---|---|---|
| `premium_enabled` | on | Defaulting off hands the paid half of the app to everyone the first time Firestore is slow |
| `minimum_build` | `0`, forcing nothing | A wrong answer locks every seller out of an app they cannot fix, with no way to ship them out of it |

The forced-update gate also has **no loading state**: until an answer arrives
the build counts as new enough, so the check can never be the reason the app
will not start.

`firestore.rules` allows any signed-in read and no write at all — a client
that could write this could switch off its own paywall.

## Indexes

`firestore.indexes.json` is the index authority. Add an index in the same
change as the query that requires it.
