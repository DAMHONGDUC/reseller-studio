# Seller OS — Final Master Plan

**Status:** Final  
**Purpose:** Product + UX + Technical source of truth  
**Platform:** Flutter  
**Backend:** Firebase  
**Design System:** `system_design/v3`

## 1. Product Vision

Seller OS is a seller operating system, not just an inventory tracker.

Core lifecycle:

```text
SOURCE → PURCHASE → INVENTORY → LIST → SELL → SHIP → PROFIT → ANALYZE → SOURCE BETTER
```

The app should answer:
- What do I have?
- Where is it?
- Where did I buy it?
- How much did it cost?
- Where is it listed?
- What needs attention today?
- What sold and what needs shipping?
- How much did I actually make?
- Which marketplace/category/source performs best?
- Which inventory is stale?
- What should I do next?

Core UX principle:

> The app should tell the seller what needs attention today, then make the action fast.

## 2. Product Principles

1. Login is mandatory; no guest mode.
2. Firebase is the backend and remote source of truth.
3. Create flows require only the minimum valid data.
4. Additional validation happens when an entity changes state.
5. Do not force sellers through long forms during quick workflows.
6. Design around seller workflows, not a large ERP-style menu.
7. Important business actions are traceable.
8. Flutter latest stable and compatible latest stable packages.
9. Clean Architecture + feature-first structure.
10. Riverpod for state management.
11. GoRouter for navigation.
12. Centralized error handling and logging.
13. Development errors must be logged to the debug console.
14. Production errors should be reported to Crashlytics.
15. Never expose raw technical errors to users.
16. Never put secrets in the Flutter client.
17. `system_design/v2` must never be modified for v3 work.
18. New UI uses `system_design/v3`.
19. v3 must not depend on v2.
20. Architecture must support future marketplace integrations, teams, subscriptions, and internationalization.
21. AI is not required for the current product direction.

## 3. Core Daily Loop

```text
OPEN APP
  ↓
DASHBOARD
  ↓
WHAT NEEDS ATTENTION?
  ├── Orders to ship
  ├── Offers waiting
  ├── Items to list
  ├── Stale inventory
  └── Marketplace/sync issues
  ↓
TAKE ACTION
  ↓
DONE
  ↓
DATA UPDATED
  ↓
ANALYTICS
```

## 4. Core Domain Model

The preferred relationship is:

```text
Source
  ↓
Purchase
  ↓
Items
  ↓
Inventory
  ↓
Listings
  ↓
Orders
  ↓
Profit
```

### Source

```text
Source
├── id
├── name
├── type
├── address
├── phone
├── website
└── notes
```

Only `name` is required.

### Purchase

```text
Purchase
├── id
├── sourceId
├── purchaseDate
├── items
├── totalCost
├── receipt
└── notes
```

`totalCost` should normally be calculated from item purchase costs.

### Item

```text
Item
├── id
├── title
├── quantity
├── purchaseId
├── purchasePrice
├── purchaseDate
├── categoryId
├── sku
├── barcode
├── condition
├── photos
├── askingPrice
├── minimumPrice
├── locationId
├── description
├── notes
└── status
```

### Listing

```text
Listing
├── id
├── itemId
├── marketplaceId
├── title
├── price
├── description
├── photos
├── status
├── externalListingId
└── externalUrl
```

### Order

```text
Order
├── id
├── marketplaceId
├── externalOrderId
├── items
├── salePrice
├── fees
├── shippingCost
├── refund
├── payout
├── status
└── timeline
```

### Expense

```text
Expense
├── id
├── categoryId
├── amount
├── date
├── vendor
├── receipt
├── notes
└── mileage
```

## 5. Navigation

Use five primary bottom tabs:

```text
Home | Inventory | Orders | Analytics | More
```

Meaning:

| Tab | User question |
|---|---|
| Home | What do I need to do today? |
| Inventory | What do I have? |
| Orders | What am I selling/processing? |
| Analytics | How is my business performing? |
| More | Where do I manage everything else? |

Do not make Sourcing, Listings, Finance, Shipping, or Offers separate bottom tabs.

Global entry points:
- Global Search
- Notifications
- Add / Quick Action

Add menu:

```text
+
├── Add Item
├── Add Purchase
├── Add Expense
└── Scan
```

## 6. Home

### Home Screen

```text
Home
├── Workspace selector
├── Notifications
├── Profile
├── Today's Overview
│   ├── Revenue
│   ├── Profit
│   ├── Orders
│   └── Inventory
├── Needs Attention
│   ├── Orders to ship
│   ├── Offers waiting
│   ├── Items to list
│   └── Stale inventory
├── Quick Actions
└── Recent Activity
```

Detail screens may include:
- Revenue Detail
- Profit Detail
- Orders Summary
- Inventory Summary
- Notifications
- Activity

## 7. Inventory

### Inventory Screen

Features:
- Search
- Filter
- Sort
- Bulk selection
- Bulk edit
- Bulk archive
- Bulk price update
- Bulk listing

Statuses:

```text
All | Listed | Reserved | Sold | Stale
```

### Item Detail

```text
Item Detail
├── Photos
├── Basic information
├── SKU / barcode
├── Status
├── Pricing
│   ├── Cost
│   ├── Asking price
│   ├── Minimum price
│   └── Expected profit
├── Purchase
│   ├── Source
│   ├── Purchase
│   ├── Purchase price
│   ├── Purchase date
│   └── Receipt
├── Location
├── Listings
├── Sales history
└── Activity
```

Actions:
- Edit
- List
- Cross-list
- Reprice
- Move
- Mark Sold
- Archive

### Add Item

```text
Add Item
├── Photos
├── Basic Info
├── Purchase
├── Pricing
├── Location
└── Save
```

### Quick Add

```text
Quick Add
├── Photo
├── Title
├── Cost
├── Selling Price
├── Source
└── Save
```

Only `Title` is required for Quick Add.

### Scanner
- Barcode
- QR
- Location
- Find item

### Locations

```text
Warehouse
├── Shelf
│   ├── Bin
│   └── Bin
└── Shelf
```

## 8. Orders

### Orders Screen

```text
All | To Ship | Shipped | Delivered | Returns
```

### Order Detail

```text
Order Detail
├── Status
├── Buyer
├── Items
├── Payment
├── Fees
├── Shipping
├── Profit
├── Tracking
└── Timeline
```

Actions:
- Ship
- Refund
- Return

### Shipping Queue

```text
To Ship
├── Order
├── Order
└── Order
```

Workflow:

```text
Pick → Pack → Shipping Label → Tracking → Shipped → Delivered
```

### Offers

Offers live under Orders:

```text
Pending | Accepted | Declined | Expired
```

Actions:
- Accept
- Decline
- Counter

## 9. Analytics

Analytics Home:
- Revenue
- Profit
- Margin
- ROI
- Orders
- Units sold
- Inventory value

Sections:
- Sales
- Profit
- Inventory
- Marketplace
- Categories
- Sources
- Expenses

### Sales
- Revenue
- Orders
- Units sold
- Average order value
- Average selling price

### Profit

```text
Revenue
- COGS
- Platform fees
- Shipping
- Other expenses
----------------
Net Profit
```

### Inventory
- Inventory value
- Sell-through
- Average days to sell
- Inventory turnover
- Stale inventory
- Average inventory age

### Marketplace
- Revenue by platform
- Profit by platform
- Fees by platform
- Orders by platform

### Category
- Revenue
- Profit
- ROI
- Sell-through

### Source
- Amount spent
- Items purchased
- Items sold
- Revenue
- Profit
- ROI

## 10. More

```text
More
├── Sourcing
├── Listings
├── Expenses
├── Reports
├── Receipts
├── Categories
├── Locations
├── Marketplaces
├── Team
└── Settings
```

## 11. Sourcing

```text
Sourcing
├── Purchases
├── Sources
├── Sourcing Trips
└── Opportunities
```

Purchase detail:
- Source
- Date
- Total cost
- Items
- Receipt

Purchase evaluation should support:
- Cost
- Expected sale price
- Marketplace
- Expected fees
- Shipping
- Expected profit
- Expected ROI
- Maximum buy price

Example:

```text
Buy price: $20
Expected sale: $60
Expected profit: $25
Expected ROI: 125%
Maximum buy price: $30
```

## 12. Listings

```text
All | Draft | Active | Paused | Ended
```

Features:
- Create/edit listing
- Listing URL
- Listing price
- Marketplace
- Listing templates
- Bulk listing
- Bulk price update
- Listing history

## 13. Cross-listing

```text
One Item
├── eBay
├── Depop
├── Poshmark
└── Shopify
```

Flow:

```text
Item → Cross-list → Select marketplaces → Review → Publish
```

Features:
- Marketplace selection
- Price mapping
- Listing status sync
- Inventory sync
- Delist after sale
- History

## 14. Marketplace Integrations

Architecture should support:
- eBay
- Etsy
- Depop
- Poshmark
- Mercari
- Shopify

Features:
- Connect
- OAuth
- Disconnect
- Sync listings
- Sync orders
- Sync inventory
- Sync prices
- Sync listing status
- Webhooks
- Connection status
- Sync history
- Sync errors

Architecture:

```text
Flutter
 ↓
Cloud Functions
 ↓
Integration Layer
 ↓
External Platform
```

Secrets remain server-side.

## 15. Pricing

Support:
- Purchase cost
- Asking price
- Minimum price
- Expected selling price
- Marketplace fees
- Shipping cost
- Expected profit
- Margin
- ROI
- Price history
- Bulk price update
- Pricing rules

If insufficient data exists:

```text
Profit: —
ROI: —
```

Do not force pricing data merely to create an item.

## 16. Returns / Refunds

```text
Order
 ↓
Return Requested
 ↓
Review
 ↓
Approve
 ↓
Refund
 ↓
Item Returned
 ↓
Inventory / Damaged / Lost
```

Features:
- Return request
- Status
- Partial/full refund
- Return shipping
- Returned inventory
- Restocking
- Return reason
- History
- Analytics

## 17. Expenses

Features:
- Add expense
- Category
- Amount
- Date
- Vendor
- Receipt
- Notes
- Recurring expense
- History

Categories:

```text
Shipping
Packaging
Advertising
Storage
Mileage
Equipment
Software
Repairs
Other
```

## 18. Receipts / Documents

Attach documents to:
- Purchases
- Expenses
- Items

Features:
- Upload
- Preview
- Archive/delete
- History

Use Firebase Storage for binary files.

## 19. Reports

Reports:
- Daily
- Weekly
- Monthly
- Yearly
- Sales
- Profit
- Expenses
- Inventory
- Tax

Export:
- CSV
- Future PDF/other formats if required

## 20. Tax

Architecture should support:
- Tax categories
- Deductible expenses
- Mileage
- Receipts
- Business expenses
- Tax reports
- Year-end summary
- Export

Tax rules must remain country-specific and configurable.

## 21. Search

Global search across:
- Items
- Listings
- Orders
- Sources
- Expenses

Search:
- SKU
- Barcode
- Item name
- Brand
- Marketplace
- Order ID
- Tracking number

## 22. Notifications

Examples:
- New order
- New offer
- Order reminder
- Shipping reminder
- Delivery update
- Stale inventory
- Low inventory
- Sync failed
- Marketplace disconnected
- Team activity

Use FCM for push notifications.

## 23. Activity / Audit Log

Track:

```text
item.created
item.updated
item.deleted
listing.created
listing.updated
listing.deleted
order.created
order.updated
order.shipped
expense.created
price.changed
```

Record:
- Who
- What
- When
- Before
- After

## 24. Workspace / Team

Features:
- Create workspace
- Workspace switching
- Invite members
- Remove members
- Roles
- Permissions
- Shared inventory
- Shared listings
- Activity history

Roles:
- Owner
- Admin
- Member
- Viewer

## 25. Settings

### Account
- Profile
- Email
- Password
- Avatar
- Delete account
- Logout

### Workspace
- Workspace name
- Country
- Currency
- Timezone
- Business type
- Logo
- Members
- Roles

### App
- Theme
- Notifications
- Currency
- Language
- Date format
- Units

### Integrations
- Marketplaces
- Shipping providers
- Payment integrations

### Subscription
- Current plan
- Billing
- Upgrade
- Downgrade
- Restore purchase

## 26. Authentication / First Launch

```text
Splash
 ↓
Login / Sign Up
 ↓
Verification where required
 ↓
Create/select Workspace
 ↓
Initial settings
 ↓
Home
```

Authentication:
- Email/password
- Sign in with Apple
- Google Sign-In
- Forgot password
- Email verification
- Session persistence
- Logout
- Account deletion

## 27. Monetization

Potential plans:

```text
Free → Pro → Business
```

Free:
- Limited inventory
- Limited listings
- Limited marketplace connections
- Basic analytics

Pro:
- Unlimited inventory
- Multiple marketplaces
- Advanced analytics
- Automation
- Reports

Business:
- Team
- Multiple workspaces
- Advanced permissions
- Advanced reports
- Higher limits

Subscription architecture may use App Store/Google Play + RevenueCat or equivalent + Cloud Functions + Firestore.

## 28. Required Field Strategy

Core rule:

> **Create = minimum required data. Transition = additional required validation.**

### Sign Up
- Email — required
- Password — required
- Confirm password — required
- Display name — optional

### Login
- Email — required
- Password — required

### Workspace
- Name — required
- Country — required
- Currency — required
- Business type — optional
- Description — optional
- Logo — optional

### Source
- Name — required
- Type — optional
- Address — optional
- Phone — optional
- Website — optional
- Notes — optional

### Purchase
- Purchase date — required
- Items — required
- Source — optional
- Receipt — optional
- Notes — optional
- Total cost — calculated where possible

### Item
- Title — required
- Quantity — required
- Purchase price — optional
- Purchase — optional
- Photos — optional
- Category — optional
- SKU — optional
- Condition — optional
- Selling price — optional
- Location — optional
- Description — optional

### Quick Add
Only:
- Title — required

Optional:
- Photo
- Cost
- Selling price
- Source

### Listing
- Item — required
- Marketplace — required
- Title — required
- Price — required
- Marketplace-specific fields — validated per platform

### Cross-listing
- Item — required
- At least one marketplace — required
- Price — can inherit from item

### Offer
- Listing/item — required
- Offer amount — required
- Expiration — optional
- Message — optional

### Manual Order
Normally orders come from integrations. If manual:
- Item — required
- Sale price — required
- Sale date — required
- Marketplace — optional
- Customer — optional
- Shipping — optional
- Notes — optional

### Shipping
Initially:
- Order — required
- Carrier — optional
- Tracking — optional
- Shipping cost — optional
- Shipping date — optional

Additional requirements apply when status becomes `Shipped`.

### Expense
- Category — required
- Amount — required
- Date — required
- Vendor — optional
- Receipt — optional
- Notes — optional
- Mileage — optional

### Receipt
- File — required
- Date — optional
- Amount — optional
- Vendor — optional
- Notes — optional

### Category
- Name — required
- Parent — optional
- Description — optional

### Location
Warehouse:
- Name — required
- Address — optional
- Notes — optional

Shelf/Bin:
- Name/code — required
- Parent location — required
- Barcode/QR — optional

### Team Invite
- Email — required
- Role — required
- Message — optional

### Marketplace Connection
- Marketplace — required
- OAuth authorization — required

## 29. State-Based Validation

Example Item lifecycle:

```text
Draft
 │
 │ Title required
 ▼
Inventory
 │
 ▼
Listed
 │
 ├── Title required
 ├── Price required
 ├── Marketplace required
 └── Marketplace-specific requirements
 │
 ▼
Sold
 │
 └── Sale information required
 │
 ▼
Shipped
 │
 └── Shipment information required
 │
 ▼
Delivered
```

This keeps Quick Add fast while preserving data integrity.

## 30. Main User Scenarios

### First-time
```text
Open → Login/Sign Up → Workspace → Settings → Home
```

### First inventory item
```text
Home → Add First Item → Quick Add → Save → Inventory
```

### Buying inventory
```text
Sourcing → New Purchase → Source → Items → Costs → Receipt → Save → Inventory
```

### Evaluate purchase
```text
Sourcing → Potential Item → Cost/Expected Sale/Fees/Shipping → Profit/ROI/Maximum Buy Price
```

### Listing
```text
Inventory → Item → Create Listing → Marketplace → Review → Publish
```

### Cross-listing
```text
Item → Cross-list → Marketplaces → Review → Publish
```

### Offer
```text
Notification → Offer → Review → Accept/Decline/Counter → Order
```

### Sale
```text
Order → Pick → Pack → Label → Ship → Tracking → Delivered
```

### Stale inventory
```text
Inventory → Stale → Select → Bulk Reprice → Update Listings
```

### Monthly review
```text
Dashboard → Monthly Report → Revenue/Profit/Expenses/Inventory → Export
```

## 31. Error Handling

Architecture:

```text
Flutter Error
Dart Error
Firebase Error
Network Error
Repository Error
UseCase Error
Provider Error
Router Error
        ↓
    AppLogger
        ↓
 ┌──────┴──────┐
 ↓             ↓
Debug       Crashlytics
Console
```

Development:
- Log error
- Log stack trace
- Include feature/action context
- Never silently swallow unexpected errors

Production:
- Crashlytics for crashes and useful non-fatal errors
- Never log passwords, tokens, secrets, or sensitive data

User-facing:

```text
Something went wrong.
Please try again.
```

Never show raw exceptions.

## 32. Security

- Firebase Authentication
- Firestore Security Rules
- Workspace-level access control
- Role-based permissions
- Server-side validation
- Secure OAuth
- Secret management
- No sensitive credentials in Flutter
- Audit logs
- Soft delete where appropriate
- Server-side authorization for critical operations

## 33. Firebase Architecture

```text
Flutter
   │
   ├── Presentation
   ├── Application
   ├── Domain
   └── Data
          │
          ▼
     Firebase Layer
          │
    ┌─────┼───────────┐
    ▼     ▼           ▼
Firestore Storage  Functions
    │       │          │
    │       │          └── Integrations / trusted logic
    │       └───────────── Images / receipts / documents
    └───────────────────── Business data
```

UI should not contain low-level Firebase operations throughout widgets.

## 34. Technical Stack

- Flutter latest stable
- Latest stable compatible packages
- Riverpod
- GoRouter
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Cloud Functions
- Firebase Cloud Messaging
- Firebase Crashlytics
- Centralized logger
- Clean Architecture
- Feature-first structure

## 35. Design System v3

Existing system:

```text
system_design/v2
```

must not be modified.

Before creating a component:

```text
v2
 ↓
Audit
 ↓
Classify
 ├── Reuse
 ├── Modify
 ├── Redesign
 └── Drop
 ↓
v3
 ↓
Seller OS
```

Rules:
1. Check v2 first.
2. Reuse useful patterns/tokens/components conceptually.
3. Create the corresponding implementation in v3.
4. Modify v3 to satisfy Seller OS requirements.
5. All Seller OS UI uses v3.
6. Never edit v2 directly.
7. v3 must not depend on v2.
8. Centralize design tokens.
9. Avoid one-off styling when a v3 component exists.

v3 should cover:
- Buttons
- Inputs
- Text
- Cards
- AppBar
- Navigation
- Dialogs
- Bottom sheets
- Lists
- Empty states
- Loading states
- Error states
- Badges
- Chips
- Tabs
- Forms
- Pickers
- Colors
- Typography
- Spacing
- Radius
- Elevation
- Motion/duration tokens

## 36. Testing

### Unit
- Entities
- Use cases
- Profit calculations
- ROI
- Pricing
- Permissions
- State transitions

### Repository
- Firestore
- Storage
- Functions
- Integration boundaries

### Widget
- Forms
- Lists
- Cards
- Dialogs
- Loading
- Error
- Empty states

### Integration
Critical flow:

```text
Login
 ↓
Create Workspace
 ↓
Add Item
 ↓
Upload Photo
 ↓
Create Listing
 ↓
Receive Order
 ↓
Ship
 ↓
Calculate Profit
 ↓
Add Expense
```

## 37. Future Expansion

Leave room for:
- More marketplaces
- Shipping providers
- Payment providers
- Accounting integrations
- Tax integrations
- Advanced automation
- Advanced reports
- Team workflows
- Multiple workspaces
- Multiple currencies
- Internationalization
- Marketplace-specific listing templates
- Advanced pricing rules
- Inventory forecasting
- Seller performance benchmarking

## 38. Final Navigation

```text
SELLER OS
│
├── HOME
│   ├── Dashboard
│   ├── Needs Attention
│   ├── Quick Actions
│   ├── Recent Activity
│   └── Notifications
│
├── INVENTORY
│   ├── Items
│   ├── Item Detail
│   ├── Add Item
│   ├── Quick Add
│   ├── Scanner
│   └── Locations
│
├── ORDERS
│   ├── Orders
│   ├── Order Detail
│   ├── Shipping Queue
│   ├── Shipping
│   ├── Offers
│   └── Returns
│
├── ANALYTICS
│   ├── Overview
│   ├── Sales
│   ├── Profit
│   ├── Inventory
│   ├── Marketplace
│   ├── Categories
│   └── Sources
│
└── MORE
    ├── Sourcing
    ├── Listings
    ├── Expenses
    ├── Reports
    ├── Receipts
    ├── Categories
    ├── Locations
    ├── Marketplaces
    ├── Team
    └── Settings
```

## 39. Definition of Done

The product architecture is considered complete when:
- Authentication is mandatory.
- Workspace security is implemented.
- Inventory can be created quickly.
- Source → Purchase → Item relationship works.
- Inventory supports business states.
- Listings can be managed.
- Orders can be processed.
- Shipping workflow exists.
- Profit is calculated from real transaction data.
- Expenses affect financial reporting.
- Analytics can trace back to sources/categories/marketplaces.
- Global search exists.
- Audit/activity history exists.
- Errors are logged to the debug console.
- Production errors are observable.
- Sensitive data is protected.
- `system_design/v2` remains untouched.
- All new UI uses `system_design/v3`.
- Critical workflows have automated tests.

## 40. Final Rule

**Do not build Seller OS as a collection of screens.**

Build it as connected seller workflows:

```text
Source
 → Purchase
 → Inventory
 → Listing
 → Offer
 → Order
 → Shipping
 → Profit
 → Analytics
 → Better Decision
```

Every screen, entity, API, Firestore collection, and UI component should support this lifecycle.
