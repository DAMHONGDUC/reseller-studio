import '../entities/order.dart';

/// Whether an order matches what the seller typed into Orders' search.
///
/// The fields a seller actually has in hand when looking for a sale: what
/// sold, who bought it, the platform's order number, the tracking number and
/// the platform's name. Case is ignored; an empty query matches everything.
final class OrderSearch {
  static bool matches(Order order, String query) {
    final String needle = query.trim().toLowerCase();

    if (needle.isEmpty) return true;

    final List<String?> haystack = <String?>[
      for (final OrderLine line in order.lines) line.title,
      order.buyerName,
      order.externalOrderId,
      order.trackingNumber,
      order.marketplaceName,
    ];

    return haystack.any(
      (String? field) => field != null && field.toLowerCase().contains(needle),
    );
  }
}
