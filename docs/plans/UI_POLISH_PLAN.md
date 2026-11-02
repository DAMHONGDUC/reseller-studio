# UI polish plan

**Status: built on `feat/dropshipping`. Its rules live in `docs/rules/DESIGN_SYSTEM.md` (Swiping and motion) and `docs/rules/SCREENS.md` (A detail screen opens on a summary). The owner removed collapsible sections on 2026-10-13 — every section is open; rows below about folding are history, not scope.**

The app-wide pass that calms every screen: less at once, the rest one tap away, short motion that says what changed. Owner approved it on 2026-10-11 — **every screen below is in scope** — built on `feat/dropshipping` **after dropshipping Phase 1** (`CLAUDE.md`).

## Principles

| | Before | After |
|---|---|---|
| How much is shown | Every section open | What the decision needs is open; the rest folds to **one summary line** |
| Top of a detail screen | First section's fields | Summary block: thumbnail, title, status, three key figures |
| Motion | Almost none | Short and calm, `SdMotionV3` only; none under system reduced motion |

Existing rules still hold: one loud element per screen, colour never the only signal, each section edits in place (`docs/rules/SCREENS.md`), Home's section order (`lib/features/home/CLAUDE.md`).

## Screens

| Screen | Before | After |
|---|---|---|
| Item detail | Eight sections open; Listings below the fold | Summary block; Listings open; Pricing, Provenance, Description, Notes folded with a summary ("Goodwill · B2"); Edit opens its section |
| Order detail | Full timeline and every section always shown | Status and **one next-step button** on top; timeline folded to the current stage; Shipping folds once delivered |
| Home | Seven sections stacked | Same order, **every section open by default** (owner, 2026-10-11), each foldable: Performance tiles behind Show less, Recent activity and Quick Action foldable; Flow overview its own card |
| Add item form | Every field shown | Title only; "More details" opens the optional fields — hard rule 2 made visible |
| Lists (Inventory, Orders, the rest) | Tap a row, then a sheet | Swipe actions for the common transition; rows fade and resize in and out |
| Analytics | Static charts | Charts draw in on first show; period switch animates |
| More, Settings, other screens | As built | Same folding section and summary line wherever a screen has secondary groups — the supplier product form's references; More stays open, being a list of destinations |

## Motion

| Effect | Where | Token |
|---|---|---|
| Expand and collapse, chevron turns 180° | Every folding section | `normal`, `standard` |
| Summary line fades as the section opens | Section header | `fast` |
| Thumbnail flies from list to detail (Hero) | Inventory → Item detail | `slow`, `emphasized` |
| A changed figure cross-fades | Profit, prices, stat tiles | `fast` |
| A row fades and resizes in and out | Every list | `fast` |
| A button settles to 0.98 under the finger | Every button | `fast` |

## Design system additions

Built in `packages/flutter-system-design-kit` under its `WIDGET_RULES.md`, committed in the submodule:

- `SdCollapsibleSectionV3` — header, summary line, chevron, animated body; remembers open state per screen.
- `SdSwipeRowV3` — a row with up to two swipe actions.
- One reduced-motion check every animated widget reads.

## Rules to write once built

- `docs/rules/DESIGN_SYSTEM.md`: folding section, swipe row, the motion table, reduced motion.
- `docs/rules/SCREENS.md`: summary block, "Edit opens its section", the folded-by-default list per screen.
- `lib/features/home/CLAUDE.md`: which Home sections start folded.
