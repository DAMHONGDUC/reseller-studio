# Subscription, paywall, and premium gates

Read this before changing plans, billing periods, paywalls, usage limits, or
any action that can be blocked by an entitlement.

## Product shape

- **The paid product is Premium, offered monthly, yearly and lifetime.**
  Owner's rule. The three are ways of paying for the same entitlement, not
  three feature tiers; choosing any of them unlocks the same capabilities.
  - **Lifetime is a one-time purchase, not a subscription.** It never renews,
    carries no trial and is never the recommended option — yearly keeps
    "Best value". It is read only from a package RevenueCat types as
    lifetime: a non-subscription product in a custom package could be a
    consumable, and selling that as "forever" is a claim the receipt breaks.
  - **The Premium entitlement must be attached to the lifetime product in
    RevenueCat.** Without it the purchase succeeds and the seller stays Free.
- **Everything is free except export.** Owner's rule, and it reverses "Free
  counts records". Free has no ceiling on items, orders, businesses or team
  seats, and payout chasing is free; the one thing Premium sells is
  `PlanFeature.export`.
  - **The ceiling machinery stays, with Free's row set to unlimited** —
    `PlanLimits.byPlan`, `PlanGate`, `PlanLimitMeters`, and the backend mirror
    in `functions/src/lib/firestore.ts` (`ceilingsByPlan`, `seatsByPlan`).
    Putting a ceiling back is a change to those two tables, not a rebuild.
  - **If a ceiling comes back, the two counts are counted differently.** Items
    are a lifetime total; orders are a rate over `PlanLimits.orderWindow`, so a
    sale that falls out of the window returns its slot on its own.
    `functions/src/subscription/usage.ts` counts the same two sets.
  - **A plan with no ceiling draws no meter**, and the paywall lists only what
    Premium adds over Free — an "Unlimited items" line Free also has is a
    promise of nothing.
- **Every capability on the paywall is refused somewhere.** Owner's rule.
  `PlanFeature` holds `export` and nothing else. A value with no gate behind
  it is a promise the product does not keep — that is why advanced analytics,
  CSV reports, automation, team, multiple businesses and roles were removed,
  and why `payoutReconciliation` went when payout chasing became free.
  `test/features/subscription/paywall_promises_test.dart` fails when a value
  has no gate named against it.
- **Every export is paid, and it is one capability.** Owner's rule. Reading a
  figure on screen is free; handing the records to a spreadsheet or an
  accountant is what Premium sells — `PlanFeature.export` covers the tax pack
  and all four CSVs, because "may this seller take their figures out" has one
  answer. Two names for that rule is how the tax summary came to be free on
  Reports while the identical tax pack was sold on Tax.
- **A locked capability shows the figure and gates the tool.** Owner's rule,
  and Tax is the shape to copy: the summary is free to read, the one-action
  pack is Premium. A locked screen that says only "upgrade to see this" is one
  nobody opens twice.
- **A downgrade never deletes existing records and never blocks a create.**
  What a lapsed seller loses is the export, not their inventory or their
  history.
- **Feature gates are the UI's, not the backend's, and that is deliberate
  here.** Export reads records the seller can already read, so a server
  boundary would add nothing a modified client could not do anyway. The seat
  limit stays enforced in the callable (`seatsByPlan`), even with Free given
  Premium's count, so a future ceiling there needs no new boundary.
- **RevenueCat client configuration is build-time environment data.** Owner's
  rule. `AppEnv` is the only reader of `REVENUECAT_API_KEY_IOS`,
  `REVENUECAT_API_KEY_ANDROID`, `REVENUECAT_ENTITLEMENT`, and
  `REVENUECAT_OFFERING`; billing code reads those fields and never repeats a
  RevenueCat dashboard identifier. The values are public client configuration,
  not credentials, but one owner still prevents a renamed offering or
  entitlement from silently disagreeing with the app.
- **The free trial is on the yearly plan only, and the paywall says so.**
  Owner's rule. The store owns the offer; the app never decides who gets one,
  it reads the product's introductory price and quotes what the store already
  promised — the same way it quotes a price rather than formatting one. A
  trial line on the monthly card would be a claim the receipt contradicts.
  - **Shown only to a seller the store says is eligible**
    (`checkTrialOrIntroductoryPriceEligibility`). An unknown answer counts as
    eligible: Android reports unknown for everyone, and the store still
    refuses a second trial — so the risk is a promise the store quietly
    declines, never a double charge.
  - **The card, the button and the fine print name the same duration and the
    price it renews at.** App Store guideline 3.1.2 wants the terms inside
    the binary, and a badge on its own is the half that gets rejected.
  - **Yearly keeps its "Best value" mark.** The trial is added to that card,
    never swapped in for the recommendation.

- **Home shows Free sellers one compact Premium banner directly above the
  shortcut row.** Owner's rule. The whole banner opens the paywall,
  and it disappears for Premium sellers so a paid customer is never advertised
  the product they already own. It stays a banner rather than a fourth shortcut
  because Home's shortcut list is closed.
- **Buying and managing Premium are separate destinations.** Owner's rule.
  `PaywallScreen` owns the purchase actions for every billing period; it has its own
  route and that route presents it as a bottom sheet. `SubscriptionScreen` is
  a separate full screen for the current plan and store billing
  management, and never doubles as the purchase surface. Premium gates and
  upgrade banners open the paywall route, while More → Subscription opens the
  management screen.
- **The paywall has a fixed footer below its scrolling content, and that
  footer is one row.** Owner's rule, and it replaces a footer built from a
  full-width Restore button stacked over a row of legal links — two controls
  and a fifth of the sheet spent on the three things a seller taps least.
  Restore Purchases, Terms of Use and Privacy Policy are compact underlined
  text links side by side, dot-separated, wrapping to a second line rather
  than growing a second control. Nothing in the footer scrolls away, none of
  it renders as a card, list rows or icon actions, and `SubscriptionScreen`
  still does not repeat Restore Purchases.
- **The paywall sells with one choice and one button.** Owner's rule. The
  billing periods are selectable option cards side by side, yearly selected
  when the sheet opens and marked as the better value; one primary CTA buys
  whichever is selected. Two full-width purchase buttons is what this
  replaced: it made the sheet tall, gave neither option a recommendation, and
  put an irreversible charge behind whichever button a thumb happened to
  reach. The selection is a controller (`PaywallSelectionController`), never
  widget state, so what is selected and what is bought cannot disagree.
- **The paywall sheet is nine tenths of the screen, and what Premium includes
  reads in two columns.** Owner's rule, and it reverses a content-sized sheet.
  This is the one surface where a fixed fraction is worth paying for: a sheet
  whose height follows whatever the store returned is a different screen on
  every open, and the strip of page left showing above it is what says the
  sheet can be dismissed. The scrolling content takes the space the footer
  does not, so the links keep the bottom edge whatever the content's height.
  Compactness comes from the content — short two-column lines rather than a
  single column of nine rows, because the seller is scanning what they get,
  not reading it — never from the sheet's own height.
- **The purchase block holds the bottom of the sheet.** Owner's rule. What
  Premium includes stays at the top under the title, while the option cards,
  the button and the fine print sit against the footer — so on a sheet fixed
  at nine tenths of the screen the slack falls between the two halves instead
  of under the last line. The thumb rests at the bottom of the phone, and that
  is where the thing it taps belongs.
- **What Premium includes sits in its own frame.** Owner's rule. The
  two-column checklist is an `SdCardV3` well under the tagline; ticks floating
  on the sheet's own surface had no edge, so they read as loose text between
  the title and the prices rather than as the thing being bought. Sunken
  rather than elevated, because it is read and never tapped — the option cards
  under it are the raised, tappable half of the sheet, and two surfaces at the
  same depth would leave nothing saying which one is the choice.
- **What is on sale is a provider, never screen state.**
  `planOfferingsProvider` loads it, `PlanOfferingCatalogue` imposes the order
  and picks the default, and the screen watches the `AsyncValue`. A failed
  load renders its own message and a retry — the earlier version caught the
  error into a local `bool` and showed an empty sheet, which reads as "there
  is nothing to buy" when the truth is that the store did not answer. The
  store's own ordering is not relied on: it is not guaranteed, and a paywall
  whose recommended option moves between launches is one nobody trusts.

## Enforcement

- The client gate decides which paywall to show; it is not the security
  boundary. The RevenueCat entitlement mirrored by a Cloud Function is what
  backend enforcement reads, following hard rules 9 and 10.
- The paywall names the exact limit that was reached and offers every billing
  period on sale for Premium. Prices are store-formatted values from RevenueCat and
  are never hardcoded or reconstructed in Flutter.
