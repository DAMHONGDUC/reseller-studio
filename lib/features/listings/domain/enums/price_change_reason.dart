/// Why a listing's price moved — what its price history explains.
///
/// Stored by [name], so a case is never renamed once written.
enum PriceChangeReason {
  /// The seller typed a new price for one listing.
  manual,

  /// A bulk reprice across a selection (hard rule 16).
  bulk,

  /// A pricing rule was applied.
  rule,

  /// A rule lowered a listing that had not sold.
  stale,

  /// A supplier's price moved and a rule followed it.
  supplierChange,
}
