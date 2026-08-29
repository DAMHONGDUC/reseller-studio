# Inventory

Read this file before changing anything in `lib/features/inventory/`.

## Item status presentation

- **An `ItemStatus` has one badge tone everywhere it appears.** Owner's rule.
  Inventory rows and Item Detail describe the same lifecycle state, so a
  status changing colour between them makes one of those screens look wrong.
  The label and tone share one presentation owner; screens never choose a tone
  themselves.

## Inventory card

- **The card shows only how many marketplaces carry the item, without names or
  marketplace prices.** Owner's rule. The asking price already owns the card's
  price line, and one count answers distribution without making a widely
  listed item taller or harder to scan. Count distinct marketplaces so two
  listing records for one platform still read as one market.
- **The Price cell matches the Cost cell's complete UI.** Owner's rule. It has
  a label above its content; only the content differs, using the arrow instead
  of an amount, and the label-to-content gap is the same in both cells. The
  whole Price cell is one circular tap target that opens the marketplace price
  list, rather than making the seller hit the arrow alone. The complete label
  and arrow stack is centred inside that circle.
- **The Inventory card's horizontal padding is equal at both edges.** Owner's
  rule. The complete circular target of the trailing actions button stays
  inside the right padding; aligning only its glyph while letting the target
  overhang makes the card's actual interactive layout asymmetric.

## Item action feedback

- **A successful item action shows no toast.** Owner's rule. The changed card,
  status, location, or price is the confirmation; a top message repeats what
  the screen already shows. Blocked actions and failures still show their
  messages because the changed record cannot explain why nothing happened.
