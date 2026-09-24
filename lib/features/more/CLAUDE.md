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
  Subscription, Theme, Language, Notifications, About, Contact support, Sign
  out and Delete account — and, in dev mode, Seed demo data and Delete all
  data last. Owner's rule: there is no separate App or Developer section.
- **Every row is drawn the way every other More row is** — owner's rule: icon,
  one-line label, the value before the chevron, hairlines between rows, no
  subtitles. A section that looks like a different screen pasted in is one the
  seller reads as a different kind of thing.
- Anything that would once have gone "in Settings" becomes a section or a row
  on More. Do not bring the screen back.

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
