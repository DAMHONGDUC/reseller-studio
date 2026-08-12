/// Fixed lists the Orders feature offers, kept off the widgets that render
/// them.
final class OrdersConstant {
  /// The carriers a reseller actually hands parcels to.
  ///
  /// **A list of suggestions, not a closed set** — the field they fill in is
  /// free text on the order, so a seller using a courier that is not here
  /// still records it. Adding a shipping *integration* is a different job and
  /// does not start with this list.
  ///
  /// Not localized: these are company names.
  static const List<String> carriers = <String>[
    'USPS',
    'UPS',
    'FedEx',
    'DHL',
    'Royal Mail',
    'Evri',
    'Australia Post',
    'Canada Post',
    'Viettel Post',
    'Giao Hàng Nhanh',
    'Other',
  ];
}
