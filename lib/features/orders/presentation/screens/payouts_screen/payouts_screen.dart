import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_marketplace_tag.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/services/payout_reconciliation.dart';
import '../../../providers.dart';
import '../../widgets/settlement_sheet.dart';

part 'payouts_screen_marketplace_card.dart';

/// Payouts — what each marketplace owes, against what it has paid (plan §8).
///
/// **`Order.payout` was writable and nothing read it in aggregate.** A blank
/// payout on one order's detail screen is invisible; forty of them is a
/// deposit that never arrived, and this is the screen where that shows up.
///
/// Grouped by marketplace because that is how the money arrives — one deposit
/// per platform, covering many orders — so reconciling a bank statement means
/// comparing one figure here against one line there.
class PayoutsScreen extends ConsumerWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MarketplacePayout> rows = ref.watch(marketplacePayoutsProvider);
    final bool settledUp = rows.every(
      (MarketplacePayout row) => row.awaiting.isEmpty,
    );

    if (rows.isEmpty) {
      return SdScaffoldV3(
        appBar: SdAppBarV3(title: context.l10n.payoutsTitle),
        body: SdEmptyStateV3(
          icon: AppIconConstant.accountBalance,
          title: context.l10n.payoutsNoSalesYet,
          message: context.l10n.payoutsNoSalesYetNote,
        ),
      );
    }

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.payoutsTitle),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          // Said once at the top rather than repeated on every card: the
          // useful fact is that nothing is outstanding anywhere.
          if (settledUp) ...<Widget>[
            SdStatTileV3(
              label: context.l10n.payoutsNothingOutstanding,
              value: context.l10n.payoutsNothingOutstandingNote,
              icon: AppIconConstant.checkCircle,
              tone: SdStatToneV3.profit,
            ),
            SizedBox(height: SdContentPaddingV3.sectionGap),
          ],
          for (final MarketplacePayout row in rows) _MarketplaceCard(row: row),
          SizedBox(height: SdContentPaddingV3.bottomGap),
        ],
      ),
    );
  }
}
