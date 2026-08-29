import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import 'domain/services/item_transition.dart';

/// Turns a refused state transition into a sentence the seller can act on.
///
/// `domain/` holds no strings (hard rule 7), so `ItemTransition` reports
/// *which* requirement is missing and this picks the localized line. "Add a
/// price to list this" is actionable; "Cannot list" is not.
final class ItemBlockPresenter {
  static String message(BuildContext context, ItemTransitionBlock block) =>
      switch (block) {
        ItemTransitionBlock.missingPrice => context.l10n.itemBlockMissingPrice,
        ItemTransitionBlock.missingSalePrice =>
          context.l10n.itemBlockMissingSalePrice,
        ItemTransitionBlock.wrongStatus => context.l10n.itemBlockWrongStatus,
        ItemTransitionBlock.noQuantity => context.l10n.itemBlockNoQuantity,
      };

  /// Every reason at once, one per line.
  ///
  /// A form that reveals one missing field per attempt is a form a seller
  /// fills in three rounds — which is why `ItemTransitionCheck` collects them
  /// all rather than stopping at the first.
  static String messages(
    BuildContext context,
    List<ItemTransitionBlock> blocks,
  ) => blocks
      .map((ItemTransitionBlock block) => message(context, block))
      .join('\n');
}
