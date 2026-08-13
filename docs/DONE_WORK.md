# Done work — what is built

What exists and works, against both the mock dataset and Firestore. Written
against the master plan's section numbers so it can be read beside it.

**Nothing here is signed off as shipped.** None of it has run against a real
Firebase project, because there is not one yet — see `RELEASE_ACTIONS.md`.
"Built" means the screens, the domain logic and the repository implementations
are there and the mock backend drives them end to end.

## By plan section

| § | Feature | State |
|---|---|---|
| 5 | Navigation — five tabs, `StatefulShellRoute.indexedStack` | built |
| 6 | Home — needs-attention, overview figures, recent activity | built |
| 7 | Inventory — list, item detail, add/edit, Quick Add, scanner, locations, categories | built |
| 8 | Orders — list, detail, shipping queue, offers | built |
| 9 | Analytics — overview plus all six drill-downs | built |
| 10 | More | built |
| 11 | Sourcing — sources ranked by ROI, purchases, purchase detail, buy calculator | built |
| 12 | Listings — filtered by status, platform rejection messages surfaced | built |
| 15 | Pricing — profit, margin, ROI, maximum buy price | built, unit-tested |
| 16 | Returns / refunds — open a return, close it, optional restock | built, no separate screen |
| 17 | Expenses — add, list, totals by category, delete | built |
| 18 | Receipts — attach to a purchase or expense, with upload | built |
| 19 | Reports — CSV export of sales, inventory and expenses via the share sheet | built |
| 21 | Search — items, orders, listings and sources in one list | built |
| 24 | Workspace / team — team screen is read-only | partial |
| 25 | Settings — account, workspace, mock-data switch (debug only) | built |
| 26 | Authentication — Apple and Google, sign out, delete account | built, unconfigured |

## What the flows actually cover

- **Auth**: Apple + Google sign-in, sign out, delete account, profile document
  written on first sign-in, workspace setup before Home. No email/password
  anywhere, by rule.
- **Inventory**: Quick Add takes a title and nothing else. Full add/edit form
  with photos, item detail, list on a marketplace, mark sold (which creates
  the order), reprice, move, archive, restore, soft delete, **bulk reprice /
  move / archive**, barcode scanner, categories, locations as
  warehouse → shelf → bin.
- **Orders**: detail with the full profit statement, ship with carrier,
  tracking and cost, mark delivered, open and close a return with optional
  restock, record fees and payout, shipping queue sorted by deadline.
- **Offers**: `Pending | Accepted | Declined | Expired`, accept (creates the
  order), decline, record a counter, and the discount off the asking price
  spelled out on the card.
- **Analytics**: the overview, the profit statement, the marketplace
  breakdown, and drill-downs for sales, profit, inventory, marketplace,
  categories and sources.

## Cross-cutting things that are done

- **Money** is integer minor units through a `Money` value type that refuses
  to mix currencies. Zero-decimal currencies (VND, JPY) handled by
  `CurrencyDecimals`, not assumed to be two.
- **Every financial figure is derived at read time.** Nothing computed is
  stored, except `orders.payoutMinor`, which is a reported fact.
- **Missing data renders `—`, never `0`.**
- **Failures** map to `AppFailure` at the `data/` boundary; no raw exception
  reaches a widget.
- **Logging** through `AppLogger`, analytics through `AppAnalytics` — a typed
  method per event, no credential or buyer detail as a parameter.
- **Localization**: 388 ARB keys in `en` and `vi` covering shared, auth,
  workspace, More, Inventory, Orders and Offers. The rest is deliberately
  deferred — `REMAINING_WORK.md`.
- **Design system**: v3 on its own generation, spacing owned entirely by
  `SdContentPaddingV3`, no `MediaQuery` read for spacing anywhere in `lib/`.
- **Read-time "now" is injected**, not read from the wall clock. `AppClock`
  and `clockProvider` (`core/time/`) are what every derived figure — overdue,
  stale, expired, days left — asks, so a test pins the instant with
  `FixedClock`. Recorded timestamps (`createdAt`, `deletedAt`, when an order
  shipped) deliberately still call `DateTime.now()`.
- **Tests**: 92 passing, none known-failing. Profit/margin/ROI including the
  plan §11 worked example, plus screen-level tests asserting rendered figures
  against the mock seed. `test/features/shot_tmp_test.dart` is the gitignored
  scratch harness and is excluded — it hangs by design.

## Things worth testing by hand first

- Sign in on a **release-signed Android build** — Google Sign-In failing only
  in release, because the release SHA-1 was never registered, is the most
  common launch-day bug in this flow.
- Creating a workspace on a fresh account: that is the sequential write the
  `firestore.rules` note in `RELEASE_ACTIONS.md` is about.
- An item with **no cost** — profit, margin and ROI must all read `—`.
- A bulk action on 20+ items.
- Airplane mode: Firestore queues the write and the app says so.
