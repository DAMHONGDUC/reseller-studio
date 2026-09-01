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
}
