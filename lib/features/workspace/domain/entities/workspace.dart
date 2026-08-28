import '../../../listings/domain/enums/listing_status.dart';
import '../../../pricing/domain/services/profit_calculator.dart';

/// A business. **Every business record in Firestore lives under one** (hard
/// rule 14), so this is the root of everything the app reads or writes.
///
/// Not the same thing as a user: one person can own two businesses, and one
/// business can have four people in it (plan §24). Conflating them is the
/// decision that makes adding a team member a migration later.
class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.country,
    required this.currency,
    required this.createdAt,
    this.timezone,
    this.businessType,
    this.logoUrl,
    this.staleThresholdDays = StaleInventoryPolicy.defaultThresholdDays,
    this.lowStockThreshold = LowStockPolicy.defaultThreshold,
    this.marketplaceFeeRates = const <String, double>{},
  });

  final String id;

  /// Required at creation, with [country] and [currency] (plan §28).
  final String name;

  final String ownerId;

  /// ISO 3166 alpha-2. Drives tax rules, which plan §20 keeps
  /// country-specific and configurable.
  final String country;

  /// ISO 4217. **The default every money field inherits.**
  ///
  /// Changing it does not convert existing records and must never try —
  /// nobody knows what rate applied to a purchase made last March.
  final String currency;

  final DateTime createdAt;
  final String? timezone;
  final String? businessType;
  final String? logoUrl;

  /// The platform commissions this business has corrected, keyed by
  /// `Marketplace.name`.
  ///
  /// **Only the corrections** — a platform absent here uses its published
  /// rate. See `MarketplaceFeePolicy`, which is the only thing that should
  /// read this map.
  final Map<String, double> marketplaceFeeRates;

  /// How long a listing sits before this workspace calls it stale. Per
  /// workspace because the right answer differs wildly: fast fashion goes
  /// stale in weeks, furniture does not.
  final int staleThresholdDays;

  /// How few items on hand before this workspace is told it is running low.
  /// Per workspace for the same reason as [staleThresholdDays]: somebody
  /// turning over forty items a week and somebody selling furniture do not
  /// mean the same thing by "low".
  final int lowStockThreshold;

  Duration get staleThreshold => Duration(days: staleThresholdDays);

  /// A copy with some fields changed.
  ///
  /// **[id], [ownerId] and [createdAt] are deliberately not settable.** They
  /// are what the business is and when it started — identity, not settings.
  ///
  /// **Changing [currency] does not convert anything and must never try**:
  /// nobody knows what rate applied to a purchase made last March. It changes
  /// what new money fields default to, and nothing else.
  Workspace copyWith({
    String? name,
    String? country,
    String? currency,
    String? timezone,
    String? businessType,
    String? logoUrl,
    int? staleThresholdDays,
    int? lowStockThreshold,
    Map<String, double>? marketplaceFeeRates,
  }) => Workspace(
    id: id,
    name: name ?? this.name,
    ownerId: ownerId,
    country: country ?? this.country,
    currency: currency ?? this.currency,
    createdAt: createdAt,
    timezone: timezone ?? this.timezone,
    businessType: businessType ?? this.businessType,
    logoUrl: logoUrl ?? this.logoUrl,
    staleThresholdDays: staleThresholdDays ?? this.staleThresholdDays,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    marketplaceFeeRates: marketplaceFeeRates ?? this.marketplaceFeeRates,
  );
}

/// Someone's membership of a workspace — the ACL row.
///
/// [displayName] and [email] are **denormalised on purpose**, so the Team
/// screen renders without reading anyone else's `users/{uid}` document, which
/// `firestore.rules` forbids. They go stale when someone renames themselves;
/// the alternative is either a leak or a fan-out read per member.
class Member {
  const Member({
    required this.uid,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final MemberRole role;
  final DateTime joinedAt;
  final String? displayName;
  final String? email;
  final String? photoUrl;
}
