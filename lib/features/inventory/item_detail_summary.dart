import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import 'domain/entities/item.dart';
import 'domain/enums/item_status.dart';

/// The one line each folded section of Item detail shows
/// (`docs/UI_POLISH_PLAN.md`): enough to decide whether to open it.
final class ItemDetailSummary {
  static String overview(BuildContext context, Item item) => _join(<String?>[
    item.title,
    item.condition?.label(context),
  ]);

  static String quantity(BuildContext context, Item item) =>
      context.l10n.itemSummaryOnHand(item.quantityOnHand);

  static String status(BuildContext context, Item item) =>
      item.status.label(context);

  static String pricing(BuildContext context, Item item) => _join(<String?>[
    '${context.l10n.itemCost} ${context.money(item.purchasePrice)}',
    if (item.expectedPrice != null)
      '${context.l10n.itemExpectedPrice} ${context.money(item.expectedPrice)}',
  ]);

  static String provenance({
    required String? source,
    required String? location,
  }) => _join(<String?>[source, location]);

  /// The first line of a long text, or `—` when there is none (hard rule 5).
  static String text(String? value) {
    final String trimmed = (value ?? '').trim();

    return trimmed.isEmpty ? '—' : trimmed.split('\n').first;
  }

  static String _join(List<String?> parts) {
    final List<String> present = <String>[
      for (final String? part in parts)
        if (part != null && part.isNotEmpty) part,
    ];

    return present.isEmpty ? '—' : present.join(' · ');
  }
}
