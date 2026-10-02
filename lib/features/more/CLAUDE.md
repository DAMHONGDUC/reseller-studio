# CLAUDE.md — More

## There is no Settings screen

Owner's rule. Everything the Settings screen held lives on More itself, and
the screen and its route are gone. A seller used to open a screen to find two
short cards they could have read from the tab — one level less is one less
place to look.

- **It is one section, General, and it comes first** — directly under the
  sync status card, above every destination section. Owner's rule: the
  controls a seller changes about the app itself sit together, not spread
  across an Account card, an Appearance card and a row in another section.
- **General holds**: the account row (who is signed in, or Sign in),
  Subscription, Theme, Language, Notifications, About, Contact support — and,
  in dev mode, Seed demo data and Delete all data last. Owner's rule: there is
  no separate App or Developer section.
- **Every row is drawn the way every other More row is** — owner's rule: icon,
  one-line label, the value before the chevron, hairlines between rows, no
  subtitles. A section that looks like a different screen pasted in is one the
  seller reads as a different kind of thing.
- Anything that would once have gone "in Settings" becomes a section or a row
  on More. Do not bring the screen back.

## Destinations are a grid of tiles; General stays rows

Owner's rule. Every section under General — Operations, Finance, Business —
is a grid of tiles, three across: a tinted icon tile over its label, which
may take two lines. General keeps the
row shape above, because it holds controls (a theme, a language) whose
current value is the point, and a tile has no room to say it.

- **A grid is where a seller goes to pick a place, rows are where they read
  a setting.** Twelve destinations as rows was a list to scan top to bottom;
  as tiles it is one glance per section.
- **A destination with no screen yet is a tile drawn faint with a "Soon"
  badge**, the same rule as the row it replaced: shown, not hidden, and no
  tap leading nowhere.
- **The tint comes from the destination, not the section**, through
  `MoreHue.of(kind)` — an exhaustive switch to an `AppTagHue`, never an index
  (the palette rule in `CLAUDE.md`), so a new destination cannot ship
  untinted.
- **Three across, not four.** At a quarter of a phone "Emplacements" or
  "Marktplätze" breaks mid-word; a third holds every shipping locale's
  longest label on two lines.
- `test/features/more/more_sections_test.dart` holds the grid, the hue and
  that every tile label fits in every shipping locale.

## The account row never prints who is signed in

Owner's rule, and it narrows the row rule above: the value beside "Account"
is always `settingsSignedIn` — never the email, never the display name.
`AccountScreen` (`presentation/screens/account_screen/`, pushed at
`AppRoutes.account`) is where those two facts actually show, along with Sign
out and Delete account, which moved there with them — a row on a list screen
is not where a destructive action belongs once it has its own screen to be
on. Everything either one needs (the dialogs, the spinner that sits on the
row that is running, the "no success message, the router replaces the whole
stack" reasoning) came across with them unchanged.

## Copy that commits to a line budget is tested, not guessed

`_SyncStatusCard` and Home's `_HomeGuestBanner` share `AppStatusCard`
(`core/widgets/`): a one-line title and a detail capped at one line for the
sync card, two for the banner. **A `maxLines` cap stops the layout breaking;
it does not stop a seller reading a sentence cut off mid-word — that is a
content bug, checked by width, not by eye.**
`test/core/widgets/status_card_text_fit_test.dart` pumps every shipping
locale's real copy through the real widget and asserts
`RenderParagraph.didExceedMaxLines` is false. A widget test needs Inter
loaded first (`test/support/load_app_fonts.dart`) — Flutter's built-in test
font is wider than Inter at nearly every weight, and measuring against it
both misses real overflow and flags copy that fits.

A string a test catches gets shortened, not exempted: the copy carries the
meaning, the width decides how much copy that can be.

## The dev rows

Seed demo data and Delete all data are the last two rows of General, behind
`devModeEnabledProvider` — checked by the section and again by each row. What
each does and why neither asks first is in `lib/features/workspace/CLAUDE.md`.
