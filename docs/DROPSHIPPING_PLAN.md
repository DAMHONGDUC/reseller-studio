# Dropshipping plan

The whole plan for bringing dropshipping — and the AutoDS-style automation it
runs on — into Reseller Studio. **Nothing in it is built until this file is
finished and the open decisions in §11 are answered** (`CLAUDE.md`, "What this
project is").

Written 2026-10-11. Platform facts in §3 come from vendor docs and third-party
guides read that day; each one is re-checked against the vendor's own
documentation before the phase that depends on it starts.

## 1. Scope

- **Same app, same records.** A dropshipped product is an item, its sale is an
  order, its price on a platform is a listing. What differs is what the item
  has (a supplier, a supplier price) and what it lacks (stock on a shelf, a
  storage location). No parallel set of screens.
- **The lifecycle it is judged against:**

  ```text
  FIND PRODUCT → LIST → SELL → ORDER FROM SUPPLIER → TRACK → PROFIT → ANALYZE → FIND BETTER
  ```

- **Manual first, connected second.** Every step works by hand before any
  connection automates it. A connection saves typing; it is never the only way
  in, and a seller on a platform with no API still runs the whole loop.
- **US and UK only**, as everywhere else. A platform or a supplier is added as
  an adapter behind one interface, never as an `if` at a call site.

## 2. AutoDS features, mapped

| AutoDS feature | Here | Phase |
|---|---|---|
| Product import from a supplier | Supplier product by URL or id; details fetched when connected, typed when not | 1 manual, 4 connected |
| Supplier price and stock monitoring | Scheduled check per supplier product; history kept | 1 manual reminder, 4 automatic |
| Automatic repricing | Pricing rules applied on demand, then on every supplier price change | 1 on demand, 5 automatic |
| Out-of-stock protection | Listing quantity set to zero on the platform when the supplier runs out | 5 |
| Automatic order placement | Supplier order requested in one tap; optional auto mode with a daily cap | 1 manual record, 4 one tap, 5 auto |
| Tracking sync | Supplier tracking flows to the order and up to the marketplace | 3 marketplace side, 4 supplier side |
| Multi-store, multi-platform | Connections per workspace; several platforms per business | 2, 3, 6 |
| Profit dashboard | Existing analytics, split by fulfilment, costs from supplier orders | 1 |
| Product research ("winning products") | **Not built** — see §10 | — |
| Store builder, buyer messaging | **Not built** — see §10 | — |

Pricing rules, price history, delist-after-sale and listing templates help
resellers as much as dropshippers, so they ship in Phase 1 for both.

## 3. Platform reality

What the platforms allow decides the order of the phases.

### Marketplaces

| Platform | API | What it gives | Constraint |
|---|---|---|---|
| eBay (US, UK) | Sell Fulfillment API | `getOrders` (two years back), `createShippingFulfillment` per package with tracking | New-order notification topics are reported unreliable; **poll** `getOrders` on a schedule |
| eBay | Sell Inventory API | Price and quantity updates on live offers | Only listings created through the API, or migrated to it, can be revised that way |
| Shopify | Admin API | Orders, fulfilments, inventory levels | `read_orders` covers 60 days; buyer name and address need **Level 2 protected customer data** review |
| Etsy | Open API v3 | Receipts, shipments, listing inventory | Serving more than a handful of shops needs **Commercial Access** — reported around 30 days of review |
| TikTok Shop (US, UK) | Partner API | Orders, fulfilment | Access status is contradictory across sources; confirm with TikTok before scheduling |
| Depop, Poshmark, Mercari, Vinted | None public | — | Stay manual, plus payout CSV import (hard rule 10) |

**eBay policy decides the supplier list.** eBay allows dropshipping only from
a wholesaler or manufacturer. Buying the item from another retailer (Amazon,
Walmart) after the sale is prohibited and gets accounts suspended. This app
therefore connects to **wholesale dropship suppliers only** and never
automates a retail purchase (§10).

### Suppliers

| Supplier | API | What it gives | Constraint |
|---|---|---|---|
| CJdropshipping | API v2, token from an API key | Product list and detail, real-time stock, orders, webhooks for product, stock, order and logistics | Webhooks time out after 3 seconds, so acknowledge first and process later |
| AliExpress | Open Platform, "DS" app category | Product, order, logistics | Order placement needs a separate approval, typically for established partners; request signing differs between sources |

**First marketplace: eBay. First supplier: CJdropshipping.** eBay has the
widest US/UK reach and an API with no review wait; CJ has the most open API.
Both are owner-confirmable in §11.

## 4. Data model

All tables are flat, top-level and keyed by id with `workspaceId` as a field
(hard rule 14). Every composite index leads with `workspaceId`. Every
hand-created document gets a sample in `sample_data/`, and
`docs/DATA_MODEL.md` is updated in the same change as each table.

### Changed tables

| Table | Change | Why |
|---|---|---|
| `items` | `fulfilment`: `stocked` (default) or `dropship`; `supplierProductId` | A dropship item has no location and no shelf count; optional at create (hard rule 2) |
| `sources` | New `SourceType.supplier`; `connectionId` when connected | A supplier *is* where stock comes from — Sourcing's ROI by source then covers suppliers with no new screen |
| `orders` | `origin`: `manual` or `synced`; `connectionId` | A synced order's id is `SdId.owned(connectionId, externalOrderId)`, so a re-poll can never create it twice |
| `listings` | `connectionId`, `externalListingId` already exists | A listing the app may revise on the platform |
| `notificationPrefs` | One switch per new type in §6 | Every type has a switch, as today |

### New tables

| Table | Fields | Notes |
|---|---|---|
| `supplier_products` | `sourceId`, `externalProductId`, `externalVariantId`, `url`, `title` (snapshot), `supplierPrice`, `supplierShipping`, `stock` (nullable), `availability`, `lastCheckedAt`, `deletedAt` | Soft-deleted (hard rule 15): items and supplier orders point at it |
| `supplier_price_changes` | `supplierProductId`, `from`, `to`, `stockFrom`, `stockTo`, `observedAt` | Append-only history; what a repricing decision is explained by |
| `listing_price_changes` | `listingId`, `from`, `to`, `reason` (`manual`, `bulk`, `rule`, `supplierChange`), `ruleId`, `changedAt` | Plan §12 "listing history" and §15 "price history" |
| `pricing_rules` | `name`, `scope` (all / marketplace / category), `multiplier`, `fixedAdd`, `rounding` (`none`, `.99`, `.00`), `minProfit`, `applyOnSupplierChange` | Floor uses `Workspace.planningFeeRate` — the one place a rate survives (hard rule 3) |
| `supplier_orders` | `orderId`, `itemId` (the order line it fulfils), `sourceId`, `supplierProductId`, `externalSupplierOrderId`, `productCost`, `shippingCost`, `status`, `trackingNumber`, `carrier`, `requestedAt`, `placedAt`, `shippedAt`, `failureCode` | One per supplier shipment; an order may have several. Its cost becomes the line's `unitCost` |
| `connections` | `platform`, `kind` (marketplace / supplier), `accountLabel`, `status` (`active`, `needsReauth`, `error`, `disconnected`), `connectedAt`, `lastSuccessAt`, `lastErrorCode`, `automation` | Client may read; `allow write: if false` |
| `connection_tokens` | Encrypted access and refresh tokens, expiry | `allow read, write: if false`; encrypted with a Cloud KMS key the Functions service account alone may use |
| `sync_runs` | `connectionId`, `job`, `startedAt`, `finishedAt`, `result`, `counts`, `errorCode` | Plan §14 "sync history" and "sync errors" |

`supplier_orders.status`:
`toOrder → requested → placed → shipped → delivered`, with `failed` and
`cancelled` off any step before `shipped`.

### Buyer address

A supplier order needs the buyer's address. **It is passed through, never
stored**: the Function placing the order reads it from the marketplace at that
moment, hands it to the supplier and keeps nothing. It is never written to
Firestore and never logged (hard rule 9). Consequence: only a synced order can
be placed automatically — a manual order's address is typed at the supplier's
own site by the seller.

## 5. Server

Everything that holds a token lives in `functions/src/integrations/`.

- **Two interfaces, one adapter per platform.**
  - `MarketplaceAdapter`: `listOrdersSince`, `pushTracking`, `setPrice`,
    `setQuantity`, `endListing`, `buyerAddress`.
  - `SupplierAdapter`: `getProduct`, `getStock`, `placeOrder`,
    `getOrderStatus`, `parseWebhook`.
  - A new platform is a new adapter and a new enum case — never a branch in a
    job.
- **OAuth without a new package.** A callable `startConnection` returns the
  platform's consent URL; the app opens it with `url_launcher`; the platform
  redirects to an `onRequest` `oauthCallback`, which exchanges the code,
  stores the token and redirects to `selleros:///more/connections`. The
  existing deep-link scheme brings the seller back.
- **Jobs.**

  | Job | Trigger | Does |
  |---|---|---|
  | `syncMarketplaceOrders` | Scheduler, every few minutes per active marketplace connection | Polls new orders, writes `orders` by deterministic id, creates `supplier_orders` in `toOrder` for dropship lines |
  | `monitorSupplierProducts` | Scheduler, hourly, grouped per supplier connection | Reads price and stock in batches, appends `supplier_price_changes`, flags listings |
  | `onSupplierOrderRequested` | Firestore trigger on `status = requested` | Reads the buyer address, calls `placeOrder`, writes `placed` or `failed` |
  | `supplierWebhook` | `onRequest` per supplier | Acknowledges at once, then applies stock, price and tracking |
  | `pushTrackingToMarketplace` | Trigger on tracking written to a `supplier_order` | Calls `pushTracking`; sets the order's `shippedAt` |
  | `applyRepricing` | Trigger on a supplier price change, when a rule allows it | Computes the new price, writes the listing and `listing_price_changes`, calls `setPrice` |
  | `outOfStockGuard` | Trigger on stock reaching zero | Calls `setQuantity(0)` on every live listing of that item |
  | `refreshTokens` | Scheduler | Refreshes before expiry; a refusal sets `needsReauth` and notifies |

- **Rules from `docs/rules/BACKEND.md` that bite hardest here:** idempotent on
  retry (a repeated `placeOrder` must not buy twice — the supplier order id is
  the idempotency key), group calls before fanning out, structured logs that
  carry the shape and never the contents, and backoff on upstream failure
  instead of skipping a seller.
- **The client never awaits any of it.** Requesting a supplier order is a
  write of `status = requested`; the trigger does the rest. That keeps
  `docs/rules/GUEST_MODE.md`'s invariant that no user-facing flow awaits the
  network.

## 6. App

Bottom tabs stay at five (hard rule 13). New screens live under More or
inside existing features.

| Where | What the seller gets |
|---|---|
| More → Connections | List of connections with status; connect, reconnect, disconnect; last error in plain words; automation level per connection. Behind `NavigationUtils.requireAccount` (hard rule 1) |
| Sourcing → Suppliers | Sources of type supplier, with their products, open orders and ROI |
| Supplier product → "List it" | Creates a dropship item and its listings at the price a pricing rule gives, shows the expected profit before saving |
| Inventory | Filter by fulfilment; a dropship row shows supplier price, supplier stock and margin at the current price |
| Listings → Pricing rules | Create, edit and delete rules; bulk "apply rule" on a selection (hard rule 16) |
| Listing detail | Price history with reasons |
| Order detail | Supplier order card: one tap "Order from supplier" when connected; "open supplier page" and fields for the supplier order number and cost when not |
| Shipping queue | Gains "to order from supplier" ahead of "to ship" |
| Home → Needs attention | Orders to place with a supplier; supplier orders that failed; supplier out of stock while listed; margin below a rule's floor after a supplier price rise; listings still live elsewhere after a sale; a connection that needs reconnecting |
| Analytics | Split by fulfilment; supplier ship time; supplier ROI through the existing source view |

**New notification types**, one switch each: `supplierOrderNeeded`,
`supplierOrderFailed`, `supplierOutOfStock`, `supplierPriceChanged`,
`connectionNeedsAttention`, `trackingAdded`.

**Profit stays measured** (hard rule 3). A dropship line's cost is its
supplier orders' product plus shipping cost; an order with no supplier order
yet shows `—` for profit (hard rule 5), never an estimate from the listed
supplier price.

**Every new string ships in all seven ARBs in the same change** (hard rule 7).

## 7. Automation levels

Per connection, chosen by the seller; the default is the most manual.

| Level | Repricing | Supplier orders |
|---|---|---|
| Off | Shown as attention only | Seller orders on the supplier's site and records it |
| Ask (default) | Proposed; one tap applies | One tap requests it |
| Auto | Applied, logged in price history | Placed without a tap, under a daily spending cap the seller sets |

- Auto-ordering spends the seller's money, so it is off until the seller turns
  it on, the cap is required when they do, and the first auto order still
  asks.
- The supplier charges the seller's own account at the supplier. The app
  never sees a card or a wallet.

## 8. Phases

Each phase ends with `make analyze` clean, the full test suite green, the
rulebook and `docs/DATA_MODEL.md` current, `docs/DONE_WORK.md` and
`docs/REMAINING_WORK.md` in step, and samples in `sample_data/`.

| Phase | Builds | Needs from the owner | Done when |
|---|---|---|---|
| 0 — Access | Developer accounts and approvals: eBay developer keys, CJ API key, Shopify Partner app, Etsy app; a Cloud KMS key; secrets in Secret Manager | Accounts in the business's name; `RELEASE_ACTIONS.md` entries | Each platform answers a sandbox call from a deployed Function |
| 1 — Manual dropshipping | Fulfilment kind on items, suppliers as sources, supplier products, manual supplier orders, pricing rules, bulk apply, listing price history, delist-after-sale attention, listing templates, analytics split | Answers in §11 | A guest runs the whole lifecycle with no connection and every number is right or `—` |
| 2 — Connection foundation | `connections`, `connection_tokens`, `sync_runs`, OAuth round trip, adapter interfaces, Connections screen, `refreshTokens`, rules and their emulator tests | Phase 0 | A seller connects and disconnects a sandbox account; a token never appears in a client read or a log |
| 3 — eBay | Orders in by polling, tracking out, price and quantity push for API-managed listings | eBay production keys | A real eBay sale appears as an order with no typing, and tracking lands on eBay |
| 4 — CJ | Product import, hourly monitor, webhooks, one-tap supplier order, tracking back | CJ account with balance | A synced eBay sale becomes a placed CJ order in one tap, and its tracking reaches eBay |
| 5 — Automation | Auto repricing, out-of-stock guard, auto ordering with the daily cap | Decision 11.2 | A supplier price rise reprices the listing, and a sale is ordered with no tap, within the cap |
| 6 — More platforms | Shopify, then Etsy, then TikTok Shop and AliExpress as access allows | Each platform's review | Each adapter passes the same contract tests as eBay or CJ |

Phases 0 and 1 run in parallel: approvals take weeks and Phase 1 needs none.

## 9. Tests

- **Pure Dart**: pricing-rule arithmetic (rounding, floor, two currencies,
  no cost recorded), dropship profit with and without supplier orders,
  supplier-order transitions, attention queries.
- **Functions**: one contract test suite per adapter interface, run against
  recorded responses; idempotency of every job under a repeated run; rules
  emulator tests proving `connections` is read-only and `connection_tokens` is
  unreadable.
- **Widget**: Connections screen states, supplier order card in each status,
  apply-rule bulk bar with 40 rows.
- Scoped by `docs/rules/TESTING.md`; no test reads `sample_data/`.

## 10. Not built

| Item | Why |
|---|---|
| Buying from Amazon, Walmart or any retailer after a sale | eBay prohibits it and suspends accounts; retailers' terms forbid automated buying |
| Product research, "winning products", trend scraping | Needs market data this app does not own; scraping breaks platform terms |
| Store builder | Shopify already is one; the app connects to the store the seller has |
| Automatic buyer messaging | Platform policies differ and a wrong message costs feedback; out of the lifecycle |
| Storing buyer addresses | §4; passed through only |

## 11. Open decisions

| # | Question | Default if unanswered |
|---|---|---|
| 11.1 | Are connections free, or Premium? Today only export is paid, and sync costs server time per seller | Premium — the first feature with a running cost |
| 11.2 | Is auto-ordering allowed at all, and with what default cap? | Allowed, off by default, cap required |
| 11.3 | `GUEST_MODE.md` forbids any sync indicator. Confirm that rule covers only the device store, so a connection's status and errors may be shown | Yes — a connection error is something the seller can act on (reconnect) |
| 11.4 | First marketplace eBay, first supplier CJ? | Yes |
| 11.5 | Buyer address passed through, never stored, so a manual order is never placed automatically? | Yes |
| 11.6 | Should the `Marketplace` enum (orders) and the connection platform enum be one list or two? Vinted is in the seller records but has no API | Two — what a seller sells on is not what the app can connect to |
