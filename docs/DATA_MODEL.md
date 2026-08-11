# Data model

The Firestore layout, and the field contracts that go with it. This file is
the authority on **what is stored and what each field is allowed to mean**;
`SELLER_OS_FINAL_MASTER_PLAN.md` is the authority on what the product does,
and `firestore.rules` is the authority on who may touch it.

## The shape

Everything is under a workspace. There is no top-level `items` or `orders`.

```text
users/{uid}                          the person, not their business
invites/{inviteId}                   pending team invites, keyed by email

workspaces/{workspaceId}
  members/{uid}                      the ACL — role lives here and nowhere else
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
  marketplaces/{marketplaceId}       connection state; tokens are server-only
  activity/{activityId}              append-only audit log
  subscription/{docId}               plan tier, written by webhook only
```

**Why nesting rather than a `workspaceId` field on flat collections.** A flat
`items` collection would make every security rule re-derive ownership from a
field on the document, and every query carry a `where('workspaceId', ...)`.
One forgotten clause is then a data leak between two sellers who have never
met. Nesting makes the workspace part of the path, so a query that forgets it
does not compile into a valid reference at all.

The cost is real and worth naming: **you cannot query across workspaces
without a collection group index**, and a user in three workspaces loads them
one at a time. That is the right trade for a product where cross-workspace
reads are a reporting nicety and cross-workspace *leaks* are fatal.

## Rules that apply to every document

- **`id` is the document id and is not stored as a field.** Storing it twice
  means it can disagree with itself.
- **Every document carries `createdAt`, `updatedAt` and `createdBy`.** The
  first two are `FieldValue.serverTimestamp()`, never a client clock — a
  phone with a wrong date would otherwise sort itself to the top of every
  list forever. `createdBy` is a Firebase UID.
- **Money is stored as an integer number of minor units** (cents, đồng), never
  a double. `19.99` is not representable in binary floating point, and a
  profit calculation that sums a few hundred of them drifts. The field name
  always says so: `purchasePriceMinor`, `salePriceMinor`.
- **Every money field has a sibling currency** or inherits the workspace's.
  A seller who buys in USD and sells in EUR is not an edge case.
- **Deletes are soft where the record is referenced by another** — `items`,
  `sources`, `purchases`, `categories`, `locations` carry `deletedAt`. Hard
  deleting a source orphans the purchases that point at it, and the seller
  loses the ROI history the whole Sourcing feature exists to show.
- **Nothing stores a computed value that can be derived** — profit, margin and
  ROI are computed at read time. A stored profit is a number that silently
  becomes wrong the moment a fee is corrected.
  - The one deliberate exception is `orders.payoutMinor`, which is what the
    marketplace actually paid and is a *fact*, not a derivation.

## The chain

The relationship the whole product is built on (plan §4):

```text
Source ──< Purchase ──< Item ──< Listing ──< Offer
                                   │
                                   └──< Order ──> Profit
```

Every arrow is a nullable id on the child, and **nullable is the point**.
Quick Add creates an item with a title and nothing else (plan §28), so
`purchaseId` is null on the item a seller photographed in a car park. The
chain is what makes analytics possible, not what makes an item valid.

## Collections

### `users/{uid}`

The person. Deliberately thin: display name, email, avatar URL, locale, and
`lastWorkspaceId` so the app reopens where they left off. **No business data
lives here** — a user is not a workspace, and treating them as one is what
makes adding a team member a migration later.

### `workspaces/{workspaceId}`

`name`, `ownerId`, `country`, `currency`, `timezone`, `businessType`,
`logoUrl`. Required at creation: name, country, currency (plan §28).

`currency` is the default every money field inherits when it does not carry
its own. Changing it does **not** convert existing records — it cannot, since
nobody knows what rate applied on a purchase made last March.

### `members/{uid}`

`role` (`owner` | `admin` | `member` | `viewer`), `displayName`, `email`,
`joinedAt`.

The name and email are **denormalised on purpose**, so the Team screen renders
without reading anyone else's `users/{uid}` document — which the rules forbid.
They go stale when someone renames themselves; that is the trade, and the
alternative is either a leak or a fan-out read per member.

### `items/{itemId}`

The plan's Item (§4), plus `status`, `deletedAt`, and denormalised
`purchaseDate` / `sourceId` copied down from the purchase.

**Why denormalise those two.** Inventory sorts and filters by purchase date
and by source, and Firestore cannot order by a field on a referenced
document. Without the copy, every Inventory query becomes N+1 reads. They are
written by the same transaction that writes the item, and a Cloud Function
trigger fixes them if the purchase is edited.

Statuses: `draft`, `inStock`, `listed`, `reserved`, `sold`, `archived`.
`stale` is **not** a status — it is a query (`status == listed` and
`listedAt` older than the workspace's threshold). Storing it as a status would
mean a nightly job flipping thousands of documents, and a seller who reprices
an item would have to wait for that job to see it leave the Stale tab.

### `listings/{listingId}`

One per item **per marketplace** — cross-listing (plan §13) means one item has
several. `externalListingId` and `externalUrl` are how the sync layer matches
a remote listing back to ours, and both are null until a publish succeeds.

### `orders/{orderId}`

`salePriceMinor`, `feesMinor`, `shippingCostMinor`, `refundMinor`,
`payoutMinor`, `status`, `marketplaceId`, `externalOrderId`, `orderedAt`,
`shipByDate`, plus an `items` array of `{itemId, quantity, unitPriceMinor}`.

The line items are **embedded, not a subcollection**. An order has a handful
of lines, they are always read with the order, and they never change after the
sale — which is exactly when embedding wins. Their `unitPriceMinor` is copied
at sale time and must never be refreshed from the item: it is what the buyer
paid, and repricing the item afterwards must not rewrite history.

### `activity/{activityId}`

`entityType`, `entityId`, `action`, `actorId`, `before`, `after`, `createdAt`.
Written only by Cloud Functions triggers (see `firestore.rules`) so `actorId`
cannot be forged. Actions are the list in plan §23.

### `marketplaces/{marketplaceId}`

Connection **status** only: which platform, connected or not, last sync time,
last error. **The OAuth tokens are not in this document and not in Firestore
at all** — they live in Secret Manager, reachable only by the functions that
call the platform. A client can read this to render "eBay · connected", and
can write nothing.

## Indexes

`firestore.indexes.json` carries a comment per index explaining which screen
it serves. Add the index in the same change as the query — a missing composite
index fails at runtime with a link to create it, which means it fails for a
user rather than in CI.
