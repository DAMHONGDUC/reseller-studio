import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../extensions/context_extensions.dart';

/// One thing this app does, as a glyph and two strings.
///
/// **Not in a feature's `domain/`** — it carries an [IconData], and `domain/`
/// is pure Dart with no Flutter imports. It is a presentation value type that
/// two features share, which is what puts it in `core/`.
@immutable
class AppFeature {
  const AppFeature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;

  /// Already localised — see [AppFeatureConstant].
  final String title;
  final String body;
}

/// **What Seller OS is, in three lines — written once and shown twice.**
///
/// The intro flow gives each one a full page; the login screen lists them
/// compactly under the app name. They are the same three claims either way,
/// and that is the point of the shared list: two screens that each described
/// the product in their own words would disagree within a release, and the one
/// a seller reads last is the one they would hold us to.
///
/// The three are the product's own chain — what you own, what you sold, what
/// it actually earned — rather than generic app-intro copy. Adding a fourth is
/// an entry here and two ARB keys; nothing else changes.
final class AppFeatureConstant {
  static List<AppFeature> of(BuildContext context) => <AppFeature>[
    AppFeature(
      icon: Symbols.inventory_2_rounded,
      title: context.l10n.onboardingInventoryTitle,
      body: context.l10n.onboardingInventoryBody,
    ),
    AppFeature(
      icon: Symbols.local_shipping_rounded,
      title: context.l10n.onboardingSellTitle,
      body: context.l10n.onboardingSellBody,
    ),
    AppFeature(
      icon: Symbols.trending_up_rounded,
      title: context.l10n.onboardingProfitTitle,
      body: context.l10n.onboardingProfitBody,
    ),
  ];
}
