# Store privacy

Code-audited disclosure for App Store Connect, Google Play and the hosted
privacy policy. This is a draft for legal review, not legal advice.

## Data inventory

| Data | Source | Storage/processor | Purpose |
|---|---|---|---|
| Name, email, avatar | Apple or Google sign-in | Firebase Auth and Firestore | Account and team identity |
| Inventory, purchases, listings, orders, expenses | Seller input | Firestore | App functionality |
| Item, receipt and workspace images | Seller upload | Firebase Storage | App functionality |
| Seller business locations and sources | Seller input | Firestore | Inventory and sourcing |
| Optional buyer name | Seller input | Firestore order | Order history |
| Crash and device diagnostics | Automatic | Firebase Crashlytics | Reliability |
| Product interactions | Automatic | Firebase Analytics | Product analytics |
| Subscription state | Store purchase | RevenueCat | Premium access |

The app does not store buyer addresses, passwords, contacts, health data,
precise location, browsing history or advertising identifiers. It does not
sell data or use data for cross-app tracking.

## App Store Connect

| Data type | Collected | Linked to user | Purpose |
|---|---|---|---|
| Contact Info: Name, Email | Yes | Yes | App Functionality |
| User Content: Photos, Other | Yes | Yes | App Functionality |
| Identifiers: User ID | Yes | Yes | App Functionality, Analytics |
| Identifiers: Device ID | Yes | Yes | Analytics |
| Usage Data: Product Interaction | Yes | Yes | Analytics |
| Diagnostics: Crash Data | Yes | Yes | App Functionality |
| Purchases: Purchase History | Yes | Yes | App Functionality |

“Used for tracking” is **No** for every row. No ATT prompt is required unless
the data flow changes.

## Google Play

| Category | Data | Purpose |
|---|---|---|
| Personal info | Name, email | Account management, app functionality |
| Photos and videos | Photos | App functionality |
| Financial info | Purchase history | App functionality |
| App activity | App interactions | Analytics |
| App performance | Crash logs, diagnostics | App functionality |
| Device identifiers | Device or other IDs | Analytics |

| Form question | Answer |
|---|---|
| Encrypted in transit | Yes |
| User can request deletion | Yes, in Settings |
| Designed for children | No |

## Hosted privacy policy draft

Fill every bracket, obtain legal review, and host this text at a stable public
URL.

### Privacy Policy — Reseller Studio

_Last updated: [date]_

**Controller.** [Legal entity name] provides Reseller Studio and is the data
controller under applicable UK and EU data-protection law. Contact:
[support email].

**Data we collect.** We process the account identity supplied by Apple or
Google; business records and images you enter; an optional buyer name attached
to an order; subscription state; crash diagnostics; and feature-usage events.
We do not request or store buyer addresses or account passwords.

**Why we use it.** We use this data to provide and synchronize the service,
support teams, manage Premium access, secure the app, and diagnose faults. Our
lawful bases are performance of our contract and our legitimate interest in a
working and secure product.

**Sharing.** We do not sell data or use it for advertising. Google Firebase
processes authentication, database, file, analytics, crash and notification
data. RevenueCat processes subscription state. Data is stored in [region].
International transfers use [safeguard].

**Retention.** We keep data while the account exists. Account deletion from
Settings removes personal data and solely owned workspaces within [n] days,
except records retained to meet a legal obligation.

**Rights.** You may access, correct, export or delete your data. Use the app's
export and deletion tools or contact [support email]. UK users may complain to
the Information Commissioner's Office.

**Children.** Reseller Studio is a business tool and is not directed to anyone
under 18.

**Changes.** We will publish policy changes at this URL and update the date.

## Before submission

| Task | Owner |
|---|---|
| Fill controller, contact, region, safeguards and retention | Business owner |
| Obtain legal review | Business owner |
| Host Privacy Policy and Terms of Use | Business owner |
| Add both URLs to store listings and build configuration | Release owner |
| Re-audit analytics and SDKs | Engineer |
