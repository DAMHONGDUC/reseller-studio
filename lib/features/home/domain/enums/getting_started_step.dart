/// The three moves that take a new seller from an empty account to a business
/// this app can report on.
///
/// **Three, and they are the spine of the lifecycle, not a tour of the app.**
/// SOURCE → INVENTORY → LIST → SELL is the chain the whole product is judged
/// against; a checklist that also asked for a category, a location and a
/// storefront would be teaching the spreadsheet this app replaces. Anything
/// the app never blocks on stays out — see the flow overview sheet, which is
/// where the full nine steps live.
enum GettingStartedStep {
  /// Quick Add. A title is the only thing it takes (hard rule 2).
  addItem,

  /// A price and a marketplace, from the item's own Actions sheet.
  listItem,

  /// Mark sold — the move that first gives Analytics something to derive.
  recordSale,
}
