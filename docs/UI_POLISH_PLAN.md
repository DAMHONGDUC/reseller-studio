# UI polish plan

The app-wide pass that makes every screen calmer: less shown at once, the
rest one tap away, and short motion that says what changed. Approved by the
owner on 2026-10-11 — **every screen below is in scope** — and built on
`feat/dropshipping` **after dropshipping Phase 1** (`CLAUDE.md`).

## Principles

| | Today | After |
|---|---|---|
| How much is shown | Every section open | What the decision needs is open; the rest collapses to **one summary line** |
| Top of a detail screen | The first section's fields | A summary block: thumbnail, title, status, three key figures |
| Motion | Almost none | Short and calm, `SdMotionV3` only; none when the system asks for reduced motion |

The existing rules still hold: one loud element per screen, colour never the
only signal, each section edits in place (`docs/rules/SCREENS.md`), and Home's
section order (`lib/features/home/CLAUDE.md`).

## Screens

| Screen | Today | After |
|---|---|---|
| Item detail | Eight sections open; Listings is below the fold | Summary block; Listings open; Pricing, Provenance, Description and Notes collapsed with a summary ("Goodwill · B2"); Edit opens its section |
| Order detail | Full timeline and every section always shown | Status and **one next-step button** on top; timeline collapsed to the current stage; Shipping collapses once delivered |
| Home | Seven sections stacked | Same order; Performance compact with "Show more"; Recent activity folded to the latest sale, Flow overview kept open for new accounts; Quick Action collapsed by default |
| Add item form | Every field shown | Title only, then "More details" opens the optional fields — hard rule 2 made visible |
| Lists (Inventory, Orders and the rest) | Tap a row, then a sheet | Swipe actions for the common transition; rows fade and resize in and out |
| Analytics | Static charts | Charts draw in on first show; switching period animates |
| More, Settings, the remaining screens | As built | The same collapsible section and summary line wherever a screen holds secondary groups |

## Motion

| Effect | Where | Token |
|---|---|---|
| Expand and collapse, chevron turns 180° | Every collapsible section | `normal`, `standard` |
| Summary line fades out as the section opens | Section header | `fast` |
| Thumbnail flies from list to detail (Hero) | Inventory → Item detail | `slow`, `emphasized` |
| A changed figure cross-fades | Profit, prices, stat tiles | `fast` |
| A row fades and resizes in and out | Every list | `fast` |
| A button settles to 0.98 under the finger | Every button | `fast` |

## Design system additions

Built in `packages/flutter-system-design-kit` under its own
`WIDGET_RULES.md`, committed in the submodule:

- `SdCollapsibleSectionV3` — header, summary line, chevron, animated body;
  remembers open state per screen.
- `SdSwipeRowV3` — a row with up to two swipe actions.
- One reduced-motion check every animated widget reads.

## Rules to write when it is built

- `docs/rules/DESIGN_SYSTEM.md`: the collapsible section, the swipe row, the
  motion table above, reduced motion.
- `docs/rules/SCREENS.md`: the summary block, "Edit opens its section", the
  collapsed-by-default list per screen.
- `lib/features/home/CLAUDE.md`: which Home sections start collapsed.
