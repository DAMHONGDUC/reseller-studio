# Dropshipping plan

The whole plan for bringing dropshipping — and the AutoDS-style automation it
runs on — into Reseller Studio. **Nothing in it is built until this file is
finished and the open decisions in §11 are answered** (`CLAUDE.md`, "What this
project is"). **Status: finished — every decision in §11 answered by the owner
on 2026-10-11.**

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

Checked against AutoDS's own features page and its Orders help article on
2026-10-11. ✅ is copied, ➕ is copied and goes further, ❌ is refused (§10).

### Products and monitoring

| AutoDS feature | Here | Phase |
|---|---|---|
| ✅ Product import from a supplier | Supplier product by URL or id; details fetched when connected, typed when not | 1 manual, 4 connected |
| ✅ Variants mapped to the supplier's | Each variant maps to a supplier variant id; decision 11.7 | 1 |
| ✅ Price and stock monitoring (AutoDS scans every 30–60 min) | Scheduled check per supplier product, plus supplier webhooks where offered; history kept | 1 manual reminder, 4 automatic |
| ✅ Minimum quantity: out of stock below a threshold, not only at zero | `minSupplierStock` on the pricing rule | 5 |
| ✅ Restock: listing comes back when the supplier does | Back-in-stock restores the platform quantity | 5 |
| ✅ Untracked products found and re-linked in one tap | A synced order or listing with no supplier product becomes attention, with "link to supplier" | 3 |
| ✅ Backup supplier, switched per product or per order | An item may hold several supplier products in order of preference | 4 |
| ✅ Winners and losers | Analytics ranks dropship items by profit and days to sell; "drop this product" from the losing end | 1 |

### Pricing

| AutoDS feature | Here | Phase |
|---|---|---|
| ✅ Profit rule: markup, fixed add, `.99` rounding | `pricing_rules` | 1 |
| ✅ Break-even that includes supplier sales tax (eBay US) | Supplier tax is a cost line on the supplier product and on the supplier order | 1 |
| ✅ Supplier shipping added to cost | `supplierShipping` | 1 |
| ✅ Automatic repricing on a supplier change | Rule-driven, logged in listing price history | 5 |
| ➕ Price optimisation by performance | Rule step: unsold for N days → lower by X%, never below the floor; uses the existing stale query | 5 |
| ✅ Bulk edit across listings | Bulk apply rule, reprice, pause, end — existing bar extended | 1 |

### Orders

| AutoDS feature | Here | Phase |
|---|---|---|
| ✅ Order statuses (pending → ordered → shipped → delivered, failed, cancelled) | `supplier_orders.status` | 1 |
| ✅ Automatic order placement | One tap, or auto with protections | 4 one tap, 5 auto |
| ✅ Maximum purchase price per supplier | Auto order stops with a reason when the supplier price is above it | 5 |
| ✅ Maximum loss per order | Auto order stops when the order would lose more than this | 5 |
| ➕ Daily spending cap | Not in AutoDS; added because auto-order spends the seller's money | 5 |
| ✅ Retry a failed order; force resend past the protections | "Try again" and "Place anyway", the second only from `failed` | 4 |
| ✅ Switch supplier for one order | Picks a backup supplier product before placing | 4 |
| ✅ Default phone number when the buyer gave none | Workspace setting, passed to the supplier | 4 |
| ✅ Shipped trigger: tracking added, or supplier processed | Per supplier connection | 4 |
| ✅ Mark delivered automatically N days after shipped | Per supplier connection, for suppliers that never report delivery | 4 |
| ✅ Days awaiting shipment (DAS) | Shown on the order; past a threshold it becomes attention | 1 |
| ✅ Estimated arrival | From the supplier product's shipping days | 1 |
| ✅ Sample order (seller buys one to check quality) | A supplier order with no sale; its cost goes to expenses | 1 |
| ✅ Cancel on the marketplace with a reason, and at the supplier | One action cancels both while the supplier order is not shipped | 3, 4 |
| ✅ Returns and refunds | Supplier refund recorded on the supplier order, so profit stays right | 1 |
| ✅ Order log | Each supplier order step is written to the activity log (hard rule 12) | 4 |
| ✅ Supplier invoice for marketplace proof of supply | Attached through the existing receipts feature | 1 |
| ✅ Filters: supplier, buy/sell price, profit, DAS, status, tracking; saved filters | Extends the existing order filters | 1 |
| ✅ Export | Existing CSV export (Premium) | 1 |

### Tracking and buyers

| AutoDS feature | Here | Phase |
|---|---|---|
| ✅ Tracking sync | Supplier tracking flows to the order and up to the marketplace | 3 marketplace side, 4 supplier side |
| ✅ Automatic buyer messages on eBay: order placed, tracking, delivered, feedback request | Templated, per message type, off by default — decision 11.8 | 6 |
| ❌ Tracking number conversion (QTrack and the like) | §10 | — |

### Channels, AI and everything else

| AutoDS feature | Here | Phase |
|---|---|---|
| ✅ Several stores and platforms | Connections per workspace; eBay, Shopify, Etsy, TikTok Shop | 2, 3, 6 |
| ✅ Profit dashboard | Existing analytics, split by fulfilment, costs from supplier orders | 1 |
| ✅ eBay title builder | The title builder above | 1 |
| ✅ eBay fee calculator | The existing buy calculator, with supplier cost as the buy price | 1 |
| ➕ AI title and description rewrite | Replaced by two on-device tools, no AI and no new service (decision 11.9): a **title builder** that assembles brand, product type, key attributes, size and condition and trims to each platform's limit; and a **supplier text cleaner** that strips filler ("2026 New Hot Sale"), emoji and repeated words. Single and bulk | 1 |
| ✅ Print on demand | A supplier adapter for a POD supplier, same interface | 6 |
| ❌ Auto-order through the seller's buyer account | §10 | — |
| ❌ Fulfilled by AutoDS (managed balance) | §10 | — |
| ❌ Product research marketplace, ads spy, trending products | §10 | — |
| ❌ AI store builder, AI image generator | §10 | — |

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
| `items` | `fulfilment`: `stocked` (default) or `dropship` | A dropship item has no location; optional at create (hard rule 2) |
| `sources` | New `SourceType.supplier`; `connectionId` when connected | A supplier *is* where stock comes from — Sourcing's ROI by source then covers suppliers with no new screen |
| `orders` | `origin`: `manual` or `synced`; `connectionId` | A synced order's id is `SdId.owned(connectionId, externalOrderId)`, so a re-poll can never create it twice |
| `listings` | `connectionId`, `externalListingId` already exists | A listing the app may revise on the platform |
| `expenses` | `supplierOrderId` on a sample order's expense | A sample is a cost with no sale |
| `workspaces` | `defaultBuyerPhone` | Suppliers refuse an order with no phone |
| `notificationPrefs` | One switch per new type in §6 | Every type has a switch, as today |

### New tables

| Table | Fields | Notes |
|---|---|---|
| `supplier_products` | `sourceId`, `externalProductId`, `externalVariantId`, `url`, `title` (snapshot), `supplierPrice`, `supplierShipping`, `supplierTax`, `shippingDays`, `stock` (nullable), `lastCheckedAt`, `itemId`, `rank`, `deletedAt` | Soft-deleted (hard rule 15): supplier orders point at it. `itemId` + `rank` replace the planned `item_suppliers` join table — one item per supplier variant (11.7) means a product stocks exactly one item, so a join table would hold nothing a column does not |
| `supplier_price_changes` | `supplierProductId`, `from`, `to`, `stockFrom`, `stockTo`, `observedAt` | Append-only history; what a repricing decision is explained by |
| `listing_price_changes` | `listingId`, `from`, `to`, `reason` (`manual`, `bulk`, `rule`, `supplierChange`), `ruleId`, `changedAt` | Plan §12 "listing history" and §15 "price history" |
| `pricing_rules` | `name`, `scope` (all / marketplace / category), `multiplier`, `fixedAdd`, `rounding` (`none`, `.99`, `.00`), `minProfit`, `minSupplierStock`, `staleDays`, `staleDropPercent`, `applyOnSupplierChange` | Floor uses `Workspace.planningFeeRate` — the one place a rate survives (hard rule 3) |
| `supplier_orders` | `orderId`, `itemId` (the order line it fulfils), `sourceId`, `supplierProductId`, `externalSupplierOrderId`, `productCost`, `shippingCost`, `tax`, `supplierRefund`, `isSample`, `status`, `trackingNumber`, `carrier`, `requestedAt`, `placedAt`, `shippedAt`, `deliveredAt`, `failureCode` | One per supplier shipment; an order may have several. Its cost less any supplier refund becomes the line's `unitCost`; a sample has no `orderId` |
| `connections` | `platform`, `kind` (marketplace / supplier), `accountLabel`, `status` (`active`, `needsReauth`, `error`, `disconnected`), `connectedAt`, `lastSuccessAt`, `lastErrorCode` | Client may read; `allow write: if false` |
| `connection_settings` | `connectionId`, `automation`, `maxPurchasePrice`, `maxLossPerOrder`, `dailySpendCap`, `shippedTrigger`, `autoDeliverAfterDays`, `buyerMessages` | The seller's choices, so the client may write them; split from `connections` so status stays server-only |
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
own site by the seller. AutoDS lets a seller edit the address in its own app;
here a supplier refusing an address fails the supplier order with that reason,
and the seller corrects it on the marketplace or places it by hand.

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
  | `outOfStockGuard` | Trigger on stock falling below the rule's `minSupplierStock` | Calls `setQuantity(0)` on every live listing of that item; restores it when stock returns |
| `checkOrderProtections` | Inside `onSupplierOrderRequested`, before `placeOrder` | Stops with a reason on max purchase price, max loss or the daily cap — unless the seller chose "Place anyway" |
| `autoDeliver` | Scheduler, daily | Marks supplier orders delivered N days after shipped, where the supplier never reports it |
| `findUnlinked` | After each order and listing sync | Flags synced rows with no supplier product, for "link to supplier" |
| `staleRepricing` | Scheduler, daily | Lowers unsold dropship listings by the rule's step, never below the floor |
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
| Listing detail | Price history with reasons; "Build title" and "Clean supplier text", previewed before they replace anything |
| Order detail | Supplier order card: one tap "Order from supplier" when connected; "open supplier page" and fields for the supplier order number and cost when not. Shows DAS, estimated arrival, failure reason, "Try again", "Place anyway", "Switch supplier", cancel both sides, supplier refund, attach supplier invoice |
| Shipping queue | Gains "to order from supplier" ahead of "to ship" |
| Home → Needs attention | Orders to place with a supplier; supplier orders past the DAS threshold; synced orders or listings not linked to a supplier; supplier orders that failed; supplier out of stock while listed; margin below a rule's floor after a supplier price rise; listings still live elsewhere after a sale; a connection that needs reconnecting |
| Analytics | Split by fulfilment; winners and losers; supplier ship time; supplier ROI through the existing source view |

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
- Three protections stop an auto order with a reason, as AutoDS's do: maximum
  purchase price per supplier, maximum loss per order, and the daily cap.
  "Place anyway" overrides them for one order, by hand only.
- The supplier charges the seller's own account at the supplier. The app
  never sees a card or a wallet.

## 8. Phases

Each phase ends with `make analyze` clean, the full test suite green, the
rulebook and `docs/DATA_MODEL.md` current, `docs/DONE_WORK.md` and
`docs/REMAINING_WORK.md` in step, and samples in `sample_data/`.

| Phase | Builds | Needs from the owner | Done when |
|---|---|---|---|
| 0 — Access | Developer accounts and approvals: eBay developer keys, CJ API key, Shopify Partner app, Etsy app; a Cloud KMS key; secrets in Secret Manager; RevenueCat offering text for connections | Accounts in the business's name; `RELEASE_ACTIONS.md` entries | Each platform answers a sandbox call from a deployed Function |
| 1 — Manual dropshipping | Fulfilment kind on items, variants, suppliers as sources, supplier products with tax and shipping days, manual supplier orders with DAS, estimated arrival, samples, supplier refunds and invoices, pricing rules, bulk apply, title builder and supplier text cleaner, listing price history, delist-after-sale attention, listing templates, order filters, analytics split with winners and losers | Answers in §11 | A guest runs the whole lifecycle with no connection and every number is right or `—` |
| 2 — Connection foundation | `connections`, `connection_tokens`, `sync_runs`, OAuth round trip, adapter interfaces, Connections screen, `refreshTokens`, `PlanFeature.connections` with its server-side gate and pause on lapse, rules and their emulator tests | Phase 0 | A seller connects and disconnects a sandbox account; a token never appears in a client read or a log |
| 3 — eBay | Orders in by polling, tracking out, price and quantity push for API-managed listings | eBay production keys | A real eBay sale appears as an order with no typing, and tracking lands on eBay |
| 4 — CJ | Product import, hourly monitor, webhooks, one-tap supplier order, retry and place anyway, backup suppliers and switch, default phone, shipped trigger, auto-deliver, order log, tracking back | CJ account with balance | A synced eBay sale becomes a placed CJ order in one tap, and its tracking reaches eBay |
| 5 — Automation | Auto repricing, stale repricing, minimum-stock guard and restock, auto ordering behind the three protections | Decision 11.2 | A supplier price rise reprices the listing, and a sale is ordered with no tap, within the cap |
| 6 — More platforms and extras | Shopify, then Etsy, then TikTok Shop and AliExpress as access allows; a POD supplier; eBay buyer messages | Each platform's review | Each adapter passes the same contract tests as eBay or CJ |

Phases 0 and 1 run in parallel: approvals take weeks and Phase 1 needs none.

**Progress.** Phase 1 is built on `feat/dropshipping`. The rule fields
only Phase 5 reads — `minSupplierStock`, `staleDays`, `staleDropPercent`,
`applyOnSupplierChange` — and the description cleaner were taken back out
before review (owner, 2026-10-12): nothing in Phase 1 set or read them, so
they land with the automation that uses them. Listing templates are
**deferred** (owner, 2026-10-11): no screen edits a listing's own description
yet, so a template has nowhere to apply. They come back with a listing editor.

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
| Auto-order through the seller's buyer account (AutoDS logs into the seller's AliExpress or Amazon account) | Means holding the seller's supplier password and driving a website as them — a credential this app must never hold (hard rules 9, 10) and a breach of those sites' terms. Official APIs only |
| Tracking number conversion | Replaces the real carrier's number with a relabelled one so the buyer does not see where it ships from; a marketplace may treat it as invalid tracking, and it misleads the buyer |
| A managed balance (Fulfilled by AutoDS) | The app would hold the seller's money and buy on their behalf — a payment service, not a seller tool |
| Product research, "winning products", trend scraping, ads spy | Needs market data this app does not own; scraping breaks platform terms |
| AI image generator | Generated product photos misrepresent the item a buyer receives |
| AI text generation | Owner chose the title builder and the text cleaner instead (11.9); no model, no new service |
| Store builder | Shopify already is one; the app connects to the store the seller has |
| Storing buyer addresses | §4; passed through only |

## 11. Decisions

All answered by the owner on 2026-10-11. Where a rule file now carries one,
it is named; the rest are carried by this plan.

| # | Question | Decision | Carried by |
|---|---|---|---|
| 11.1 | Connections free or Premium? | **Premium**, gated in the backend too; a lapse pauses and deletes nothing | `docs/rules/SUBSCRIPTION.md` |
| 11.2 | Auto-ordering allowed, and with what cap? | **Allowed, off by default**; turning it on requires a daily cap; the first auto order still asks | §7 |
| 11.3 | Does `GUEST_MODE.md`'s ban on sync indicators cover connections? | **No** — it covers the device store only; a connection's status and last error are shown | `docs/rules/GUEST_MODE.md` |
| 11.4 | First marketplace and supplier? | **eBay, then CJdropshipping** | §3, §8 |
| 11.5 | Buyer address stored? | **Never** — passed through to the supplier at placement | `docs/rules/PRIVACY_AND_SECURITY.md` |
| 11.6 | One platform list or two? | **Two**: what a seller sells on (`Marketplace`) and what the app can connect to (a connection platform enum) | §4 |
| 11.7 | Variants? | **One item per supplier variant** in Phase 1; a variant table when multi-variation listings are built | §4 |
| 11.8 | Automatic eBay buyer messages? | **Built, every type off by default** | §2, Phase 6 |
| 11.9 | AI rewrite through a new service? | **No.** A rule-based title builder and a supplier text cleaner, on device, in Phase 1 | §2, §6 |
