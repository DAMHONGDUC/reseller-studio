# Inventory

Read this file before changing anything in `lib/features/inventory/`.

## Item status presentation

- **An `ItemStatus` has one badge tone everywhere it appears.** Owner's rule.
  Inventory rows and Item Detail describe the same lifecycle state, so a
  status changing colour between them makes one of those screens look wrong.
  The label and tone share one presentation owner; screens never choose a tone
  themselves.

## Inventory card

- **The card lists every marketplace carrying the item, without marketplace
  prices.** Owner's rule. The asking price already owns the card's price line;
  the marketplace line answers distribution only, so repeating a separate
  figure for each platform adds noise and makes a widely listed item harder to
  scan.

## Item action feedback

- **A successful item action shows no toast.** Owner's rule. The changed card,
  status, location, or price is the confirmation; a top message repeats what
  the screen already shows. Blocked actions and failures still show their
  messages because the changed record cannot explain why nothing happened.
