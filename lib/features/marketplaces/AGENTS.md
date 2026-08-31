# Marketplaces

Read this file before changing anything in `lib/features/marketplaces/` or a
workflow that creates a workspace.

## Seller-owned marketplace records

- **A marketplace is a record the business owns, never a closed enum.** The
  seller can add, rename, change the estimated fee rate, and delete a
  marketplace. A fixed list turns every local platform or offline venue into
  "Other", which makes marketplace analytics unable to name where a sale
  happened.
- **The marketplace detail screen owns editing and deletion.** A list row
  opens that screen; the list itself does not carry inline fee controls. One
  editing surface keeps the name and estimated rate in one transaction and
  gives deletion enough context to explain its effect.
- **Delete is an app-bar icon on marketplace detail.** It appears only for an
  existing marketplace and still opens the confirmation dialog. Keeping the
  destructive action in the chrome leaves the form body for editable fields
  and the pinned bottom action for Save alone.
- **The delete action uses `AppIconConstant.delete` at the normal app-bar icon
  size.** Owner's rule. The registry currently resolves it to Flutter's
  `Icons.delete_outline_rounded`; the screen does not choose between Material
  Icons and Symbols itself.
- **There is no "Use published rate" toggle.** The marketplace record always
  carries the business's current estimated fee rate, and the seller edits it
  directly on the detail screen. A published rate and an override are two
  competing answers to one field after marketplaces become seller-owned
  records.
- **Delete is soft-delete.** Listings and orders point at a marketplace id, so
  removing the document would erase the marketplace name from historical
  records and reports (hard rule 15).

## New-business defaults

- **Every new business starts with eBay, Etsy, Depop, Poshmark, and Vinted.**
  Each is created as a normal marketplace record with its default estimated
  fee rate, so the seller can list immediately and can later edit or delete
  any of them. Vinted starts at a zero seller fee because its current standard
  seller flow charges the buyer rather than deducting a selling fee.
- **The five defaults and the user's workspace pointer share one final batch.**
  Firestore rules require the workspace and owner membership to exist in two
  earlier writes, so creation is workspace → membership → one batch containing
  all five marketplaces and the profile pointer. A partial default list is
  indistinguishable from a seller-edited list; withholding the pointer until
  that batch succeeds keeps an incomplete business out of the app.
- **Default names, ids, and rates have one owner in code.** Workspace creation
  consumes that definition; no controller or screen repeats the values.

## A marketplace carries a colour, and every row that names one wears it

Owner's rule. A seller scanning orders reads the platform before they read
anything else on the card, and eight identical grey badges make that a reading
task instead of a glance.

- **The hue is `AppTagHue`, stored by name.** The app already owns a named set
  of hues that are only required to differ from each other, and a second
  palette for marketplaces would be the same list twice. It is never indexed by
  number (root `CLAUDE.md`), and an unknown or missing stored name falls back
  to `AppTagHue.grey` — a marketplace written by a later build must still
  render.
- **Grey is the default, not an absence.** A marketplace the seller adds has no
  colour opinion yet; the five seeded ones each start on a different hue so the
  feature is visible without anybody configuring it.
- **`AppMarketplaceTag` and `AppMarketplaceDot` are the only two presenters.**
  In `core/widgets/`, because orders, home, payouts and analytics all name a
  marketplace and none of them may map an id to a colour itself. Both read
  `marketplaceHuesProvider`, so a renamed hue reaches every screen at once.
- **Colour is never the only signal.** The name is always spelled out beside
  the tag or the dot; the hue is a second way to find a row, never the only
  one. A seller may give two marketplaces the same colour and nothing breaks.
- **The marketplace breakdown on Analytics uses these hues, not the chart
  series.** A platform that is amber on an order card and blue on a bar chart
  is two colours for one thing.
- **Listings, offers and cross-list are deliberately left plain.** They run off
  the legacy closed `Marketplace` enum rather than the seller's records, so
  most of their ids resolve to no record and every row would come out grey.
  They join this rule when they move onto the records.
