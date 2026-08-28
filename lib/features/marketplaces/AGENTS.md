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
- **The delete action uses Flutter's `Icons.delete_outline_rounded` at the
  normal app-bar icon size.** Owner's rule. The smaller Symbols glyph was too
  light and too hard to recognise in the chrome.
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
