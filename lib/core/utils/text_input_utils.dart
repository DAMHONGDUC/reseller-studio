/// What a text box's contents mean once the seller has finished with them.
///
/// Extracted on its second copy — the item form and the item detail sections
/// both had to answer the same question, and two copies is how one of them
/// ends up storing `''` where the other stores null.
final class TextInputUtils {
  /// An empty box means "not entered", which is a **null** field rather than
  /// an empty string. The two look identical on screen and completely
  /// different in a query: `where('barcode', isNull: true)` misses every row
  /// that stored the empty one.
  static String? orNull(String value) {
    final String trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  /// [value] read as a count, moved by [by], and never below zero.
  ///
  /// **An unreadable box counts as zero**, so `+1` on an empty field gives
  /// one — the same answer saving an empty box already writes.
  static int stepCount(String value, int by) {
    final int current = int.tryParse(value.trim()) ?? 0;
    final int next = current + by;

    return next < 0 ? 0 : next;
  }
}
