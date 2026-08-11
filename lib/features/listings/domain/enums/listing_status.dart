/// Where a listing is (plan §12).
enum ListingStatus {
  /// Composed but never published. Cross-listing produces these in bulk.
  draft,

  /// Live and buyable.
  active,

  /// Live but hidden — a holiday, or stock held back.
  paused,

  /// Ended without a sale: expired, or pulled by the seller.
  ended,

  /// Ended because it sold.
  sold,

  /// The platform rejected or removed it. **Distinct from [ended] on
  /// purpose** — this one needs the seller to do something, and folding it
  /// into a generic "ended" is how a policy strike goes unnoticed.
  error;

  bool get isLive => this == ListingStatus.active || this == ListingStatus.paused;
}

/// Expense categories (plan §17).
enum ExpenseCategory {
  shipping,
  packaging,
  advertising,
  storage,
  mileage,
  equipment,
  software,
  repairs,
  other;

  /// Whether this category is typically deductible.
  ///
  /// **A hint for the tax report, not tax advice, and not a rule.** Plan §20
  /// says tax rules stay country-specific and configurable; this is a default
  /// the workspace's own settings override. Never present it to a user as a
  /// determination.
  bool get isTypicallyDeductible => true;
}

/// What a member may do (plan §24).
///
/// Ordered from most to least privileged. `firestore.rules` is the real
/// enforcement — this enum is how the UI decides what to grey out, and a
/// client-side check is never the security boundary.
enum MemberRole {
  owner,
  admin,
  member,
  viewer;

  /// Can create and edit business records.
  bool get canWrite => this != MemberRole.viewer;

  /// Can change the workspace, its members and their roles.
  bool get canAdminister =>
      this == MemberRole.owner || this == MemberRole.admin;

  /// Can delete the workspace or transfer it. Owner only.
  bool get canOwn => this == MemberRole.owner;
}

/// Where a seller sources stock (plan §11).
enum SourceType {
  thriftStore,
  estateSale,
  garageSale,
  auction,
  wholesale,
  retailArbitrage,
  onlineMarketplace,
  consignment,
  donation,
  other,
}
