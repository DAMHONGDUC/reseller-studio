# Inventory

Read this file before changing anything in `lib/features/inventory/`.

## Item status presentation

- **An `ItemStatus` has one badge tone everywhere it appears.** Owner's rule.
  Inventory rows and Item Detail describe the same lifecycle state, so a
  status changing colour between them makes one of those screens look wrong.
  The label and tone share one presentation owner; screens never choose a tone
  themselves.
