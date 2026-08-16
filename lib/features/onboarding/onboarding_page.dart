import 'package:flutter/widgets.dart';

/// One page of the intro flow.
///
/// A value type rather than three hand-written screens: the pages differ only
/// in their glyph and their words, and three copies of the same layout is how
/// the spacing on page two drifts away from page one.
///
/// **Not in `domain/`** — it carries an [IconData], and `domain/` is pure Dart
/// with no Flutter imports (`CLAUDE.md`). It is a presentation value type, so
/// it sits at the feature root beside the class that builds the list.
@immutable
class OnboardingPage {
  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;

  /// Already localised — see `OnboardingPageContent`.
  final String title;
  final String body;
}
