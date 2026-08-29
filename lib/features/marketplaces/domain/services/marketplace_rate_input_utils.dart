/// Converts the percentage shown in the marketplace form into a stored rate.
final class MarketplaceRateInputUtils {
  /// Accepts both decimal separators because device keyboards follow locale.
  static double? parse(String input) {
    final String normalized = input.trim().replaceAll(',', '.');
    final double? percent = double.tryParse(normalized);

    return percent == null ? null : percent / 100;
  }
}
