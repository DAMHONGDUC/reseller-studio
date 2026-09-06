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

## Workspace creation includes marketplace and category defaults

The marketplace rules live in `lib/features/marketplaces/AGENTS.md`, and the
category rules live in `lib/features/inventory/CLAUDE.md`. Workspace creation
owns their write because the user's workspace pointer must not become visible
before the new business has every default record.

- Creation stays workspace → owner membership → final batch, because Firestore
  rules can validate membership only after both earlier documents are
  committed.
- The final batch contains the marketplace defaults, category defaults, and
  the user's workspace list and last-workspace pointer. A failure therefore
  leaves an unreachable workspace rather than a reachable business with a
  partial default list.

## Two screens, and they are not the same job

Owner's rule, and it **replaces "More → Business opens the business the seller
is currently standing in"**. There are now two:

- **`WorkspacesScreen` (More → Businesses)** manages the *list*: every
  business the seller belongs to, the plan's ceiling on how many, and the one
  action that spends the next slot. It names no record, so its row on More is
  a plain `const` destination — `MoreConstant.sectionsFor` no longer takes a
  workspace id, and the current business is one tap away, marked with a badge.
- **`WorkspaceDetailScreen`** edits *one* business.

**The switcher sheet stays a switcher.** It opens from Home's title mid-task
and closes the moment a business is picked — the wrong surface for a plan
meter, an empty state or a list somebody is auditing.

**Both list surfaces use one interaction, deliberately.** Tapping a row
switches to that business; the pencil beside it opens the detail screen. Two
gestures that do different things must not swap places between the sheet and
the screen.

## One screen edits a business, and two places open it

Owner's rule. `WorkspaceDetailScreen` is where a business's name, country,
currency, business type and thresholds are changed, and it is reached from
both places a seller sees a list of businesses:

- **the switcher sheet**, where every row carries an edit affordance beside
  it — so the business you want to correct is editable from the list you were
  already looking at, without switching to it first;
- **the Businesses screen**, the same affordance on the same kind of row.

**Settings does not show the business at all any more.** Owner's rule, and it
replaces the rule that used to stand here — that Settings held the facts and
an Edit row. Settings is now what its name says: the device's theme, the
account, and the developer block. A business is a record, records are managed
from More, and a seller looking for their business had to know it was filed
under a screen about preferences.

- **Settings no longer edits a field in place** either. It used to open a
  picker per row and write on the tap; two screens writing the same document
  is the state where one of them quietly stops matching.

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
- **Both verbs are pinned, Delete above Save.** The record this screen
  destroys is the record it edits, so Delete is the screen's action and not a
  card's — it scrolled off the end of the form until the pinned-action rule in
  `docs/rules/SCREENS.md` was widened. Save stays lowest, so the button under
  a resting thumb is never the destructive one.

## Emptying a business is not deleting it, and they are different code paths

The developer block in More → Settings has two opposite buttons, and the rule
is that neither one is a version of the other:

- **Seed demo data** fills the open workspace (`DemoDataSeeder`, in
  `lib/features/seed_data/`).
- **Delete all data** empties it (`WorkspacePurgeRepository`). The business
  survives, so this is not `deleteWorkspace` with a flag — that one ends the
  record this one leaves standing, is owner-only, and is a Cloud Function.
- **Two tables survive the sweep, and the list says which**:
  `WorkspaceCollections.recordTableNames` is `tableNames` minus `members` (the
  ACL, hard rule 11 — emptying it locks every seller out of a business that
  still exists) and `activity` (append-only, hard rule 12 — `firestore.rules`
  refuses the delete, so including it would fail the sweep on its first row).
  It is **derived** from `tableNames`, so a table added there is swept without
  anyone remembering a second list.
- **A client sweep, not a callable**, unlike deleting the business: the rules
  already let a member delete a row in every table it touches, so the Admin
  SDK would buy nothing. It is paged, 400 rows at a time, under the batch cap.
- **It hard-deletes, deliberately against hard rule 15.** A soft delete keeps
  a row joinable for whatever points at it, and nothing points at anything
  once the sweep finishes — a workspace full of `deletedAt` rows is not the
  empty workspace this exists to reproduce.
- **Dev mode gates it twice**, the section and the card, the same as the seed
  card beside it: this one deletes, so one guard being forgotten must not be
  enough.
- Its strings are hardcoded English, the developer-UI exception to hard rule 7
  that `_SeedDataCard` already takes.
- `test/features/workspace/delete_all_data_test.dart` pins what survives.
