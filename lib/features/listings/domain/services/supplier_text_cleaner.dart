import '../../listing_text_constant.dart';

/// Strips the padding supplier copy arrives with (`docs/DROPSHIPPING_PLAN.md`,
/// decision 11.9 — rules, not a model).
///
/// It only removes: nothing is reworded and nothing is invented, so a cleaned
/// text never says more about the item than the supplier did.
final class SupplierTextCleaner {
  /// [title] without filler, hype years, emoji, brackets or repeated words.
  static String cleanTitle(String title) {
    final Set<String> seen = <String>{};
    final List<String> kept = <String>[];
    final String stripped = _withoutBrackets(
      _withoutFiller(_withoutEmoji(title)),
    );

    for (final String word in stripped.split(RegExp(r'\s+'))) {
      final String bare = word.replaceAll(_edgePunctuation, '');

      if (bare.isEmpty) continue;
      if (seen.add(bare.toLowerCase())) kept.add(bare);
    }

    return _titleCasedIfShouting(kept.join(' '));
  }

  /// [description] as plain text, without markup, emoji, filler or the lines
  /// that speak to resellers rather than buyers.
  static String cleanDescription(String description) {
    final String plain = _decodeEntities(
      description.replaceAll(_lineBreakTags, '\n').replaceAll(_anyTag, ''),
    );
    final List<String> lines = <String>[];

    for (final String line in _withoutEmoji(plain).split('\n')) {
      final String lower = line.toLowerCase();
      final bool sellerOnly = ListingTextConstant.sellerOnlyLines.any(
        lower.contains,
      );
      final String cleaned = _tidied(_withoutFiller(line));

      if (sellerOnly) continue;
      lines.add(cleaned);
    }

    return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static final RegExp _emoji = RegExp(
    r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}]',
    unicode: true,
  );
  static final RegExp _hypeYear = RegExp(
    r'\b(?:(?:19|20)\d{2}\s+(?:new|newest|latest)|(?:new|newest|latest)\s+(?:19|20)\d{2})\b',
    caseSensitive: false,
  );
  static final RegExp _brackets = RegExp(r'[【】\[\]{}「」『』]');
  static final RegExp _edgePunctuation = RegExp(
    r'^[,;:/|\-–—!.]+|[,;:/|\-–—!]+$',
  );
  static final RegExp _lineBreakTags = RegExp(
    r'<\s*(?:br|/p|/div|/li)\s*/?\s*>',
    caseSensitive: false,
  );
  static final RegExp _anyTag = RegExp(r'<[^>]*>');
  static final List<RegExp> _filler = <RegExp>[
    for (final String phrase in <String>[
      ...ListingTextConstant.fillerPhrases,
    ]..sort((String a, String b) => b.length.compareTo(a.length)))
      RegExp('\\b${RegExp.escape(phrase)}\\b', caseSensitive: false),
  ];

  static String _withoutEmoji(String text) => text.replaceAll(_emoji, '');

  static String _withoutFiller(String text) {
    String result = text.replaceAll(_hypeYear, ' ');

    for (final RegExp phrase in _filler) {
      result = result.replaceAll(phrase, ' ');
    }

    return result;
  }

  /// Mends what a removal leaves: stray spaces before punctuation, doubled
  /// or leading punctuation, and a lower-case first letter.
  static String _tidied(String line) {
    final String tidy = line
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAllMapped(RegExp(r'\s+([.,;:!?])'), (Match m) => m[1]!)
        .replaceAllMapped(RegExp(r'([.,;:!?])\1+'), (Match m) => m[1]!)
        .replaceAll(RegExp(r'^[\s.,;:!?]+'), '')
        .trim();

    return tidy.isEmpty ? tidy : '${tidy[0].toUpperCase()}${tidy.substring(1)}';
  }

  static String _withoutBrackets(String text) =>
      text.replaceAll(_brackets, ' ').replaceAll(RegExp(r'\(\s*\)'), ' ');

  static String _decodeEntities(String text) => text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');

  /// A title written all in capitals reads as shouting on every platform, so
  /// it becomes title case; one with any lower case is left as written.
  static String _titleCasedIfShouting(String title) {
    if (title.isEmpty || title != title.toUpperCase()) return title;
    if (title == title.toLowerCase()) return title;

    return title
        .split(' ')
        .map(
          (String word) => word.length <= 1
              ? word
              : '${word[0]}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
