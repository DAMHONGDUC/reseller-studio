# Subscription, paywall, and premium gates

Read before changing plans, billing periods, paywalls, usage limits, or any action an entitlement can block.

## Product shape

- **The paid product is Premium: monthly, yearly and lifetime.** Owner's rule. Three ways to pay for one entitlement, not three tiers; each unlocks the same capabilities.
  - **Lifetime is a one-time purchase, not a subscription.** It never renews, has no trial and is never the recommended option — yearly keeps "Best value". It is read only from a package RevenueCat types as lifetime: a non-subscription product in a custom package could be a consumable, and selling that as "forever" is a claim the receipt breaks.
  - **Attach the Premium entitlement to the lifetime product in RevenueCat.** Without it the purchase succeeds and the seller stays Free.
- **Everything is free except export.** Owner's rule; it reverses "Free counts records". Free has no ceiling on items, orders, businesses or seats, and payout chasing is free. Premium sells one thing: `PlanFeature.export`.
  - **The ceiling machinery stays, with Free's row set to unlimited** — `PlanLimits.byPlan`, `PlanGate`, `PlanLimitMeters`, and the backend mirror in `functions/src/lib/firestore.ts` (`ceilingsByPlan`, `seatsByPlan`). Restoring a ceiling edits those two tables; nothing is rebuilt.
  - **If a ceiling returns, the two counts differ.** Items are a lifetime total; orders a rate over `PlanLimits.orderWindow`, so a sale leaving the window frees its slot by itself. `functions/src/subscription/usage.ts` counts the same two sets.
  - **A plan with no ceiling draws no meter**, and the paywall lists only what Premium adds over Free — an "Unlimited items" line Free also has promises nothing.
- **Marketplace and supplier connections are Premium.** Owner's rule, the one exception to "free except export": a connection is the first feature with a running cost per seller — every poll, monitor run and supplier call is server time (`docs/plans/DROPSHIPPING_PLAN.md`).
  - **Gated in the backend as well as the UI**, unlike export. A Function that syncs, monitors or places an order reads the workspace's entitlement first; an app-only gate would let a modified client run the servers for free.
  - **A lapse pauses connections and deletes nothing.** Status goes to paused, synced records stay, the manual workflow keeps working — the downgrade rule below, applied to connections.
  - `PlanFeature` gains `connections` when Phase 2 ships, not before: the next rule forbids a paywall line with no gate.
- **Every capability on the paywall is refused somewhere.** Owner's rule. `PlanFeature` holds `export` alone. A value with no gate is a promise the product breaks — so advanced analytics, CSV reports, automation, team, multiple businesses and roles were removed, and `payoutReconciliation` went when payout chasing became free. `test/features/subscription/paywall_promises_test.dart` fails on a value with no gate named against it.
- **Every export is paid, as one capability.** Owner's rule. Reading a figure on screen is free; handing records to a spreadsheet or accountant is what Premium sells. `PlanFeature.export` covers the tax pack and all four CSVs: "may this seller take their figures out" has one answer. Two names for that rule is how the tax summary was free on Reports while the identical tax pack was sold on Tax.
- **A locked capability shows the figure and gates the tool.** Owner's rule; copy Tax: the summary is free to read, the one-action pack is Premium. A locked screen saying only "upgrade to see this" is opened once.
- **A downgrade never deletes records and never blocks a create.** A lapsed seller loses the export, not their inventory or history.
- **Feature gates are the UI's, not the backend's — on purpose here.** Export reads records the seller can already read, so a server boundary adds nothing a modified client could not do. The seat limit stays enforced in the callable (`seatsByPlan`), even with Free given Premium's count, so a future ceiling there needs no new boundary.
- **RevenueCat client config is build-time environment data.** Owner's rule. `AppEnv` alone reads `REVENUECAT_API_KEY_IOS`, `REVENUECAT_API_KEY_ANDROID`, `REVENUECAT_ENTITLEMENT` and `REVENUECAT_OFFERING`; billing code reads those fields and never repeats a dashboard identifier. The values are public client config, not credentials — but one owner stops a renamed offering or entitlement silently disagreeing with the app.
- **The free trial is on yearly only, and the paywall says so.** Owner's rule. The store owns the offer; the app never decides who gets one. It reads the product's introductory price and quotes what the store promised — as it quotes a price rather than formatting one. A trial line on the monthly card is a claim the receipt contradicts.
  - **Shown only to a seller the store calls eligible** (`checkTrialOrIntroductoryPriceEligibility`). Unknown counts as eligible: Android reports unknown for everyone, and the store still refuses a second trial — so the risk is a promise the store quietly declines, never a double charge.
  - **Card, button and fine print name the same duration and renewal price.** App Store guideline 3.1.2 wants the terms in the binary; a badge alone is the half that gets rejected.
  - **Yearly keeps "Best value".** The trial is added to that card, never swapped in for the recommendation.

- **Home shows Free sellers one compact Premium banner just above the shortcut row.** Owner's rule. The whole banner opens the paywall, and it disappears for Premium sellers — a paying customer is never sold what they own. A banner, not a fourth shortcut, because Home's shortcut list is closed.
- **Buying and managing Premium are separate destinations.** Owner's rule.
  - `PaywallScreen` owns purchase actions for every billing period; its own route presents it as a bottom sheet.
  - `SubscriptionScreen` is a separate full screen for the current plan and store billing management, never a purchase surface.
  - Premium gates and upgrade banners open the paywall route; More → Subscription opens the management screen.
- **The paywall has a fixed footer below its scrolling content, and the footer is one row.** Owner's rule. It replaced a full-width Restore button stacked over legal links — two controls and a fifth of the sheet spent on the three things a seller taps least.
  - Restore Purchases, Terms of Use and Privacy Policy are compact underlined text links side by side, dot-separated, wrapping to a second line rather than growing a second control.
  - Nothing in the footer scrolls away or renders as a card, list rows or icon actions.
  - `SubscriptionScreen` still does not repeat Restore Purchases.
- **The paywall sells with one choice and one button.** Owner's rule. Billing periods are selectable option cards side by side, yearly selected on open and marked better value; one primary CTA buys the selection. It replaced two full-width purchase buttons: a tall sheet, no recommendation, and an irreversible charge behind whichever button a thumb reached. The selection is a controller (`PaywallSelectionController`), never widget state, so selected and bought cannot disagree.
- **The paywall sheet is nine tenths of the screen, and what Premium includes reads in two columns.** Owner's rule; it reverses a content-sized sheet.
  - The one surface where a fixed fraction pays: a sheet sized by whatever the store returned is a different screen each open, and the strip of page above it says the sheet can be dismissed.
  - Scrolling content takes the space the footer leaves, so the links hold the bottom edge whatever the content height.
  - Compactness comes from content — short two-column lines, not a single column of nine rows, because the seller scans what they get — never from the sheet's height.
- **The purchase block holds the bottom of the sheet.** Owner's rule. What Premium includes stays at the top under the title; option cards, button and fine print sit against the footer. On a sheet fixed at nine tenths, the slack falls between the halves, not under the last line. The thumb rests at the bottom of the phone, where its target belongs.
- **What Premium includes sits in its own frame.** Owner's rule. The two-column checklist is an `SdCardV3` well under the tagline: ticks floating on the sheet had no edge and read as loose text between title and prices, not as the thing bought. Sunken, not elevated, because it is read and never tapped — the option cards below are the raised, tappable half; two surfaces at one depth would leave nothing saying which is the choice.
- **What is on sale is a provider, never screen state.** `planOfferingsProvider` loads it, `PlanOfferingCatalogue` sets the order and picks the default, and the screen watches the `AsyncValue`.
  - A failed load renders its own message and a retry. The earlier version caught the error into a local `bool` and showed an empty sheet — "nothing to buy" when the store simply did not answer.
  - The store's own ordering is not relied on: it is not guaranteed, and a paywall whose recommendation moves between launches is trusted by no one.

## Enforcement

- The client gate picks which paywall to show; it is not the security boundary. Backend enforcement reads the RevenueCat entitlement mirrored by a Cloud Function (hard rules 9, 10).
- The paywall names the exact limit reached and offers every billing period on sale. Prices are store-formatted values from RevenueCat, never hardcoded or rebuilt in Flutter.
