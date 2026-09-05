/// The business types offered at workspace setup.
///
/// **Codes only — no words.** A label is a user-facing string and belongs in
/// the ARB files (hard rule 7), so this holds what the app *stores* and
/// `WorkspaceOptionLabel` holds what a seller reads.
///
/// **Neither the countries nor the currencies are here.** `CountryConstant`
/// and `CurrencyConstant` each hold the whole ISO set and are the only lists —
/// see `lib/features/workspace/CLAUDE.md`.
final class WorkspaceConstant {
  /// Optional at creation (plan §28) — it drives nothing today and exists so
  /// the tax work later has something to branch on. Stored as these keys, not
  /// as the words a seller picked, or the record would change meaning with
  /// the app's language.
  static const List<String> businessTypes = <String>[
    'soleTrader',
    'partnership',
    'limitedCompany',
    'hobbySeller',
  ];

  /// How long a listing may sit before this workspace calls it stale, in days.
  ///
  /// A short list of round numbers rather than a free number field: the answer
  /// is a judgement about how fast the seller's stock moves, and asking them
  /// to type 63 invites a precision nobody has. `StaleInventoryPolicy` owns
  /// the default and it is one of these.
  static const List<int> staleThresholdChoices = <int>[14, 30, 60, 90, 180];

  /// How few items on hand before this workspace is told it is running low.
  ///
  /// Round numbers for the same reason as the list above, and `LowStockPolicy`
  /// owns the default — which is one of these.
  static const List<int> lowStockChoices = <int>[5, 10, 20, 50, 100];

  /// What this business assumes a platform takes, when it is working out
  /// whether a buy is worth making.
  ///
  /// **A planning assumption, and the only rate left in the app** (hard rule
  /// 3). Sourcing and the cross-list comparison run before any sale exists, so
  /// they have nothing to measure; everything after a sale reads the payout.
  /// One number rather than one per marketplace: a seller standing in a shop
  /// does not yet know which platform it will sell on.
  static const List<double> planningFeeRateChoices = <double>[
    0.05,
    0.10,
    0.13,
    0.15,
    0.20,
  ];

  /// The middle of the range above, and close to what eBay and the mid-tier
  /// platforms charge — the rate a new business plans with until it says
  /// otherwise.
  static const double defaultPlanningFeeRate = 0.13;
}
