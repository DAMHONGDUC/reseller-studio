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
- **There is no "Use published rate" toggle.** The marketplace record always
  carries the business's current estimated fee rate, and the seller edits it
  directly on the detail screen. A published rate and an override are two
  competing answers to one field after marketplaces become seller-owned
  records.
- **Delete is soft-delete.** Listings and orders point at a marketplace id, so
  removing the document would erase the marketplace name from historical
  records and reports (hard rule 15).

## New-business defaults

- **Every new business starts with eBay, Etsy, Depop, and Poshmark.** Each is
  created as a normal marketplace record with its default estimated fee rate,
  so the seller can list immediately and can later edit or delete any of them.
- **The four defaults are written atomically with workspace creation.** A
  partial default list is indistinguishable from a seller-edited list, so the
  workspace and all four marketplace records must either be created together
  or not at all.
- **Default names, ids, and rates have one owner in code.** Workspace creation
  consumes that definition; no controller or screen repeats the values.
