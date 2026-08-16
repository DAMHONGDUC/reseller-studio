import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/extensions/context_extensions.dart';
import 'onboarding_page.dart';

/// The words and glyphs of the intro flow.
///
/// Split from [OnboardingPage] the way `WorkspaceOptionLabel` is split from
/// `WorkspaceConstant`: the strings are user-facing and go through ARB (hard
/// rule 7), so building the list needs a [BuildContext] and cannot be a
/// `const` list on the value type.
///
/// **The three pages are the product's own chain**, not generic app-intro
/// copy: what you own, what you sold, what it actually earned. A seller who
/// reads them should be able to say what this app is for.
final class OnboardingPageContent {
  static List<OnboardingPage> of(BuildContext context) => <OnboardingPage>[
    OnboardingPage(
      icon: Symbols.inventory_2_rounded,
      title: context.l10n.onboardingInventoryTitle,
      body: context.l10n.onboardingInventoryBody,
    ),
    OnboardingPage(
      icon: Symbols.local_shipping_rounded,
      title: context.l10n.onboardingSellTitle,
      body: context.l10n.onboardingSellBody,
    ),
    OnboardingPage(
      icon: Symbols.trending_up_rounded,
      title: context.l10n.onboardingProfitTitle,
      body: context.l10n.onboardingProfitBody,
    ),
  ];
}
