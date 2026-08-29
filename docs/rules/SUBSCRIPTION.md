# Subscription, paywall, and premium gates

Read this before changing plans, billing periods, paywalls, usage limits, or
any action that can be blocked by an entitlement.

## Product shape

- **The paid product is Premium, offered monthly and yearly.** Owner's rule.
  Monthly and yearly are billing periods for the same entitlement, not two
  feature tiers; choosing either unlocks the same product capabilities.
- **Free is limited by Inventory usage, Order usage, and business count.**
  Owner's rule. The ceilings live only in `PlanLimits.free`; documents and UI
  copy read those fields and never repeat their values. Premium gates sit
  before the blocked create action, so the seller never fills a form and then
  learns that it cannot be saved.
- **A downgrade never deletes existing records.** The gate blocks the next
  create once usage is at or above the Free ceiling; inventory, order history,
  and businesses already stored remain readable.
- **RevenueCat client configuration is build-time environment data.** Owner's
  rule. `AppEnv` is the only reader of `REVENUECAT_IOS_KEY`,
  `REVENUECAT_ANDROID_KEY`, `REVENUECAT_ENTITLEMENT`, and
  `REVENUECAT_OFFERING`; billing code reads those fields and never repeats a
  RevenueCat dashboard identifier. The values are public client configuration,
  not credentials, but one owner still prevents a renamed offering or
  entitlement from silently disagreeing with the app.
- **Home shows Free sellers one compact Premium banner directly above the
  shortcut row.** Owner's rule. The whole banner opens the subscription screen,
  and it disappears for Premium sellers so a paid customer is never advertised
  the product they already own. It stays a banner rather than a fourth shortcut
  because Home's shortcut list is closed.
- **Buying and managing Premium are separate destinations.** Owner's rule.
  `PaywallScreen` owns the monthly and yearly purchase actions; it has its own
  route and that route presents it as a bottom sheet. `SubscriptionScreen` is
  a separate full screen for the current plan, restore, and store billing
  management, and never doubles as the purchase surface. Premium gates and
  upgrade banners open the paywall route, while More → Subscription opens the
  management screen.

## Enforcement

- The client gate decides which paywall to show; it is not the security
  boundary. The RevenueCat entitlement mirrored by a Cloud Function is what
  backend enforcement reads, following hard rules 9 and 10.
- The paywall names the exact limit that was reached and offers both billing
  periods for Premium. Prices are store-formatted values from RevenueCat and
  are never hardcoded or reconstructed in Flutter.
