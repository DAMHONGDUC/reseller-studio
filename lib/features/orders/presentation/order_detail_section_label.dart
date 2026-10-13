import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import 'controllers/order_detail_edit_controller.dart';

/// The heading of each editable Order detail section.
///
/// The section header and the editing app bar both name it, so one switch
/// answers for both.
final class OrderDetailSectionLabel {
  static String of(BuildContext context, OrderDetailSection section) =>
      switch (section) {
        OrderDetailSection.order => context.l10n.orderSectionOrder,
        OrderDetailSection.profit => context.l10n.commonProfit,
        OrderDetailSection.shipping => context.l10n.commonShipping,
      };
}
