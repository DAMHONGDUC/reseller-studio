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
| Derived finance | Never store profit, margin or ROI |
| Payout exception | `orders.payoutMinor` is stored because it is a reported fact |
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
| `users/{uid}` | `displayName`, `email`, `avatarUrl`, `locale`, `lastWorkspaceId`, `workspaceIds` | Person and workspace pointers only; no business records |
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
| `marketplaces/{id}` | `name`, `feeRate`, `deletedAt` | Seller-owned; `feeRate` is a planning estimate, never accounting |
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

## Order contract

| Group | Fields |
|---|---|
| Money | `salePriceMinor`, `feesMinor`, `shippingCostMinor`, `refundMinor`, `payoutMinor` |
| Marketplace | `marketplaceId`, `marketplaceName`, `externalOrderId` |
| Lifecycle | `orderedAt`, `shipByDate`, `shippedAt`, `deliveredAt`, `returnRequestedAt`, `returnedAt`, `refundedAt`, `settledAt` |
| Lines | `{itemId, title, quantity, unitPriceMinor, unitCostMinor}` |

Lifecycle timestamps remain facts even after status changes. Lines are embedded
because they are small, always read with the order, and immutable after sale.

## Indexes

`firestore.indexes.json` is the index authority. Add an index in the same
change as the query that requires it.
