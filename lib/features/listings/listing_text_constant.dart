/// Platform title limits and the supplier filler the text cleaner removes
/// (`docs/DROPSHIPPING_PLAN.md`, decision 11.9).
final class ListingTextConstant {
  /// Title limits by marketplace record id, as the platforms enforced them in
  /// 2026-10. A record the app does not know takes [defaultTitleLength].
  static const Map<String, int> titleLengths = <String, int>{
    'ebay': 80,
    'etsy': 140,
    'poshmark': 80,
    'mercari': 80,
    'shopify': 255,
  };

  /// eBay's limit — the tightest of the common ones, so a title built to it
  /// fits almost anywhere.
  static const int defaultTitleLength = 80;

  /// Phrases a supplier pads a title with, matched whole and
  /// case-insensitively. The cleaner tries the longest first.
  static const List<String> fillerPhrases = <String>[
    'factory direct sale',
    'free shipping',
    'fast shipping',
    'drop shipping',
    'dropshipping',
    'new arrival',
    'new arrivals',
    'hot selling',
    'best selling',
    'best seller',
    'high quality',
    'top quality',
    'factory direct',
    'factory price',
    'limited time',
    'big sale',
    'hot sale',
    'wholesale',
    'in stock',
    'promotion',
  ];
}
