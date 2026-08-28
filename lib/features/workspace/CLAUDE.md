# CLAUDE.md — workspace

Rules specific to the business a seller creates, configures and switches
between. The root `CLAUDE.md` still applies in full; this file only holds what
would be wrong to generalise.

## The country picker offers every country

Owner's rule, and it replaces the short list `WorkspaceConstant` used to hold.
A seller whose business is not in one of nine countries could not create one at
all — setup is the gate, so a missing country was a lost account, and the
launch-market rule in the root `CLAUDE.md` is about which tax rules ship, never
about who is allowed to sign up.

- **`CountryConstant.codes` is the whole ISO 3166-1 alpha-2 set and the only
  list.** There is no second, shorter copy kept for onboarding: two lists is
  how one of them ends up missing the country somebody is standing in.
- **Ordered by the name a seller reads, not by code.** The codes are what is
  stored; the alphabet the picker scrolls through has to be the one on screen.
- **A list that long is only usable with a search box**, which is why
  `OptionPickerSheet` takes a `searchHint`. See `docs/rules/DESIGN_SYSTEM.md`.

## The currency picker offers every currency too

Owner's rule, and it **replaces the rule that used to stand here** — that the
currency list could stay short because a country is a fact about the seller
while a currency is a default the money layer has to have been got right for.
The second half of that was true, so it was done rather than argued with: the
money layer is now right for every ISO 4217 currency, and the list opened
after that, not before. Offering 249 countries and eight currencies left most
of those sellers keeping their books in somebody else's money.

- **`CurrencyConstant.codes` is the whole active ISO 4217 set and the only
  list**, ordered by the name a seller reads. Same shape as `CountryConstant`,
  same reasons, and there is no second shorter copy.
- **`CurrencyLabel` is its own file**, away from `WorkspaceOptionLabel`, for
  the reason `CountryLabel` is: hundreds of arms would bury the four
  business-type ones that file exists for.
- **`CurrencyPicker` is the one presenter**, searchable, with the code as each
  row's caption so somebody who thinks in codes can type GBP.
- **`CurrencyDecimals` had to be completed first, and is the real cost of this
  rule.** It carries the full zero-decimal set *and* the three-decimal one —
  the Gulf and North African dinars plus the Omani rial — which it previously
  skipped on the explicit grounds that none of them was selectable. The moment
  the picker offered KWD, that reasoning became a factor-of-ten error in every
  amount a Kuwaiti business entered.
  **Anything added to the currency list is checked against that file.**
- **`IDR` is a deliberate deviation from ISO**, which gives the rupiah an
  exponent of 2. The sen has not circulated in decades, the app already
  treated it as zero-decimal, and changing it now would multiply every stored
  rupiah amount by a hundred.
- `test/features/workspace/currency_list_test.dart` holds the list — every
  code distinct, every code with words, ordered by name — and
  `test/core/money/currency_decimals_test.dart` holds the arithmetic.

## Country names go through the ARB files like every other string

Hard rule 7, with no exception — 249 names is a reason to generate the keys,
never a reason to hardcode English into a constant.

- The keys are `country<Xx>`, one per alpha-2 code, and `CountryLabel.of` is
  the single lookup. It is long and mechanical on purpose: `context.l10n` has
  no dynamic key lookup, so the alternative is a map of English strings, which
  is the rule being broken with extra steps.
- **An unknown code falls back to itself.** A workspace created on a later
  build must still render its row rather than showing a blank.
- The English values come from the public-domain `iso3166.tab` in the tz
  database. They are short display names, not the ISO long forms — "Bolivia",
  not "Bolivia (Plurinational State of)" — because the picker is a list to
  scan, and the long forms bury the word the seller is looking for.

## One screen edits a business, and two places open it

Owner's rule. `WorkspaceDetailScreen` is where a business's name, country,
currency, business type and thresholds are changed, and it is reached from
both places a seller sees a business:

- **the switcher sheet**, where every row carries an edit affordance beside
  it — so the business you want to correct is editable from the list you were
  already looking at, without switching to it first;
- **Settings**, where the business card shows the facts and an Edit row opens
  the same screen.

**Settings no longer edits a field in place.** It used to open a picker per
row, and adding a second way in would have made two screens that both write
the same document — the state where one of them quietly stops matching. The
card is now what it always was for a member: the facts, plus the one way to
change them.

- **It is a form with a pinned save, not a row that writes on tap** — the
  screens rule in `docs/rules/SCREENS.md`. Nothing is written until the seller
  saves, so correcting the country and the currency together is one write.
- **It takes a workspace id, never "the current one".** The switcher can open
  it on a business the seller is not standing in, and a controller reading
  `currentWorkspaceProvider` would have silently edited the wrong record.
- **The workspace is re-read at the moment of the write**, not held from when
  the screen opened: a teammate renaming the business in between would
  otherwise be undone by a stale copy. Only the fields the form owns are
  applied.
- **Deleting stays here too**, owner-only, behind the same confirmation — it
  is a change to the same record and splitting it across two screens is how a
  destructive action ends up somewhere nobody looks for it.
