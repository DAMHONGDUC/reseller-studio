import '../../listing_text_constant.dart';
import '../entities/title_parts.dart';

/// Assembles a listing title from its parts, inside a platform's limit
/// (`docs/DROPSHIPPING_PLAN.md`, decision 11.9 — rules, not a model).
///
/// - Order: brand, product type, attributes, colour, size, condition.
/// - A word already used is not repeated, whatever its case.
/// - Over the limit, the least important parts go first: the last attribute,
///   then colour, then condition. Brand, product type and size are kept, and
///   only cut — at a word boundary — when they alone are too long.
final class TitleBuilder {
  /// The title for [parts], at most [maxLength] characters.
  static String build(TitleParts parts, {required int maxLength}) {
    final List<_Segment> segments = _segments(parts);
    final List<_Segment> droppable =
        segments.where((_Segment segment) => segment.dropOrder != null).toList()
          ..sort(
            (_Segment a, _Segment b) => a.dropOrder!.compareTo(b.dropOrder!),
          );
    String title = _join(segments);

    for (final _Segment segment in droppable) {
      if (title.length <= maxLength) break;
      segments.remove(segment);
      title = _join(segments);
    }

    return _cutAtWord(title, maxLength);
  }

  /// The title limit of a marketplace record, by its id.
  static int maxLengthFor(String marketplaceId) =>
      ListingTextConstant.titleLengths[marketplaceId] ??
      ListingTextConstant.defaultTitleLength;

  static List<_Segment> _segments(TitleParts parts) {
    final Set<String> seen = <String>{};
    final List<_Segment> segments = <_Segment>[];
    final int attributeCount = parts.attributes.length;
    final List<(String?, int?)> ordered = <(String?, int?)>[
      (parts.brand, null),
      (parts.productType, null),
      for (int index = 0; index < attributeCount; index++)
        (parts.attributes[index], attributeCount - 1 - index),
      (parts.color, attributeCount),
      (parts.size, null),
      (parts.condition, attributeCount + 1),
    ];

    for (final (String? text, int? dropOrder) in ordered) {
      final String unique = _unseenWords(text, seen);

      if (unique.isNotEmpty) segments.add(_Segment(unique, dropOrder));
    }

    return segments;
  }

  /// [text]'s words that [seen] does not hold yet, recording them as it goes.
  static String _unseenWords(String? text, Set<String> seen) {
    final List<String> kept = <String>[];

    for (final String word in (text ?? '').trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      if (seen.add(word.toLowerCase())) kept.add(word);
    }

    return kept.join(' ');
  }

  static String _join(List<_Segment> segments) =>
      segments.map((_Segment segment) => segment.text).join(' ');

  static String _cutAtWord(String title, int maxLength) {
    if (title.length <= maxLength) return title;

    final String head = title.substring(0, maxLength);

    if (title[maxLength] == ' ') return head.trim();

    final int lastSpace = head.lastIndexOf(' ');

    return (lastSpace > 0 ? head.substring(0, lastSpace) : head).trim();
  }
}

/// One part of a title; [dropOrder] null means it is never dropped.
class _Segment {
  _Segment(this.text, this.dropOrder);

  final String text;
  final int? dropOrder;
}
