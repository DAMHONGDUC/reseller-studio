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

workspaces/{workspaceId}
  members/{uid}
  sources/{sourceId}
  purchases/{purchaseId}
  items/{itemId}
  listings/{listingId}
  offers/{offerId}
  orders/{orderId}
  expenses/{expenseId}
  receipts/{receiptId}
  categories/{categoryId}
  locations/{locationId}
  marketplaces/{marketplaceId}
  carriers/{carrierId}
  activity/{activityId}
  subscription/{docId}
  usage/{docId}
```

Business records are nested under a workspace. This makes workspace membership
part of every path and prevents a query from accidentally omitting an ownership
filter.

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

| Field | Meaning |
|---|---|
| `premiumEnabled` | Whether the plan system applies at all |

`premiumEnabled: false` turns monetisation off for everyone: `currentPlanProvider`
answers Premium, so no ceiling blocks a create and every capability is
included, and the Subscription row and the Home upgrade banner are not drawn.

**A missing document, a missing field, a mistyped value or a failed read all
resolve to `AppConfig.fallback`, which has monetisation ON.** The document is
edited by hand, so a typo is the likely failure, and the one thing it must not
do is hand the paid half of the app to everyone. Same direction as
`currentPlanProvider` falling back to Free.

`firestore.rules` allows any signed-in read and no write at all — a client
that could write this could switch off its own paywall.

## Indexes

`firestore.indexes.json` is the index authority. Add an index in the same
change as the query that requires it.
