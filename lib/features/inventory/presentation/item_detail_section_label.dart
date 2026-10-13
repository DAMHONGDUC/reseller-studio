import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import 'controllers/item_detail_edit_controller.dart';

/// The heading of each Item detail section.
///
/// The section header and the editing app bar both name it, so one switch
/// answers for both.
final class ItemDetailSectionLabel {
  static String of(BuildContext context, ItemDetailSection section) =>
      switch (section) {
        ItemDetailSection.overview => context.l10n.itemOverview,
        ItemDetailSection.quantity => context.l10n.commonQuantity,
        ItemDetailSection.status => context.l10n.itemStatus,
        ItemDetailSection.pricing => context.l10n.itemPricing,
        ItemDetailSection.provenance => context.l10n.itemProvenance,
        ItemDetailSection.description => context.l10n.commonDescription,
        ItemDetailSection.notes => context.l10n.commonNotes,
      };
}
