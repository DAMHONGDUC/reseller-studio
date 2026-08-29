# Subscription, paywall, and premium gates

Read this before changing plans, billing periods, paywalls, usage limits, or
any action that can be blocked by an entitlement.

## Product shape

- **The paid product is Premium, offered monthly and yearly.** Owner's rule.
  Monthly and yearly are billing periods for the same entitlement, not two
  feature tiers; choosing either unlocks the same product capabilities.
- **Free is limited by Inventory usage, Order usage, and business count.**
  Owner's rule. A Free seller can create only one business. Premium gates sit
  before the blocked create action, so the seller never fills a form and then
  learns that it cannot be saved.
- **A downgrade never deletes existing records.** The gate blocks the next
  create once usage is at or above the Free ceiling; inventory, order history,
  and businesses already stored remain readable.

## Enforcement

- The client gate decides which paywall to show; it is not the security
  boundary. The RevenueCat entitlement mirrored by a Cloud Function is what
  backend enforcement reads, following hard rules 9 and 10.
- The paywall names the exact limit that was reached and offers both billing
  periods for Premium. Prices are store-formatted values from RevenueCat and
  are never hardcoded or reconstructed in Flutter.
