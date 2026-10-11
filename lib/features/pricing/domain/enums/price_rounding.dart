/// How a rule's computed price is rounded.
///
/// Stored by [name], so a case is never renamed once written.
enum PriceRounding {
  /// The computed price, to the minor unit.
  none,

  /// Ends in .99 — `$23.40` becomes `$23.99`.
  ninetyNine,

  /// A whole unit — `$23.40` becomes `$24.00`.
  whole,
}
