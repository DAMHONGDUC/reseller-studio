/// The countries, currencies and business types offered at workspace setup.
///
/// **Codes only — no words.** A label is a user-facing string and belongs in
/// the ARB files (hard rule 7), so this holds what the app *stores* and
/// `WorkspaceOptionLabel` holds what a seller reads.
///
/// **A short list, not every ISO code.** Onboarding is the one screen a seller
/// has no reason to trust yet, and a 180-row picker is where they stop. The
/// full list belongs behind a search box in Settings when someone asks for it.
///
/// The currency a workspace is created with is the default every money field
/// inherits, and **changing it later does not convert existing records** —
/// nobody knows what rate applied to a purchase made last March.
final class WorkspaceConstant {
  /// ISO 4217 codes. Order is the order the picker shows them in: the ones
  /// this product's sellers actually use, first.
  static const List<String> currencies = <String>[
    'USD',
    'EUR',
    'GBP',
    'VND',
    'AUD',
    'CAD',
    'JPY',
    'SGD',
  ];

  /// ISO 3166 alpha-2 codes.
  static const List<String> countries = <String>[
    'US',
    'GB',
    'VN',
    'AU',
    'CA',
    'DE',
    'FR',
    'JP',
    'SG',
  ];

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
}
