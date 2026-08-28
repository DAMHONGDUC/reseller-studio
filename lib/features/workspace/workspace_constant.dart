/// The currencies and business types offered at workspace setup.
///
/// **Codes only — no words.** A label is a user-facing string and belongs in
/// the ARB files (hard rule 7), so this holds what the app *stores* and
/// `WorkspaceOptionLabel` holds what a seller reads.
///
/// **The countries are not here.** `CountryConstant` holds every one of them
/// and is the only list — see `lib/features/workspace/CLAUDE.md` for why the
/// currency list below stays short while that one does not.
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
