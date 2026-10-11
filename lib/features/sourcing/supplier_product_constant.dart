/// Thresholds for a dropship supplier's products.
final class SupplierProductConstant {
  /// Days after which a supplier's price and stock are worth checking again
  /// — the manual half of monitoring until a supplier is connected.
  static const int recheckAfterDays = 14;
}
