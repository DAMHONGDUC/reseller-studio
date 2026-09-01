import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// What a string will take on screen, before it is on screen.
///
/// **For reserving a slot, not for laying one out.** A block whose text
/// changes with a selection moves everything anchored to it; measuring the
/// alternatives lets the slot keep one height instead.
final class TextMeasureUtils {
  /// The height of the tallest of [texts], laid out at [maxWidth].
  static double tallestHeight({
    required List<String> texts,
    required TextStyle style,
    required double maxWidth,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    double tallest = 0;

    for (final String text in texts) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: maxWidth);

      tallest = math.max(tallest, painter.height);
      painter.dispose();
    }

    return tallest;
  }
}
