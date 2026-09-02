import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../orders/domain/entities/order.dart';
import '../../../../sourcing/domain/entities/purchase.dart';
import '../../../domain/services/bookkeeping_gaps.dart';
import '../../../providers.dart';

part 'books_screen_group.dart';

/// Everywhere the books are still guessing, and what to do about each.
///
/// **The mirror image of Home.** Home answers "what needs doing today" at the
/// start of a day; this answers "what is my sheet still missing" at the end of
/// one — the question every reseller asks the night before they hand anything
/// to an accountant, and the one the app had no screen for.
///
/// It exists because being honest about missing data is only half the job.
/// Hard rule 5 makes the app render `—` rather than invent a figure, and
/// `Order.effectiveFees` labels an estimate rather than passing it off as
/// fact. Both are right, and neither gets the number entered: without this
/// screen those em dashes were scattered across hundreds of records with no
/// way to find them.
///
/// **Every row hands off to the screen that owns the record.** Nothing is
/// edited here — the same rule Home follows — so there is exactly one place
/// that knows how to write a fee, and this screen never becomes a second one.
class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BookkeepingGaps gaps = ref.watch(bookkeepingGapsProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.booksTitle),
      body: gaps.isClear
          ? SdEmptyStateV3(
              icon: AppIconConstant.checkCircle,
              title: context.l10n.booksClearTitle,
              message: context.l10n.booksClearBody,
            )
          : ListView(
              padding: SdContentPaddingV3.fullBleed(context),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SdContentPaddingV3.horizontal,
                  ),
                  child: Text(
                    context.l10n.booksIntro(gaps.total),
                    style: context.textTheme3.bodySmall!.muted3(context),
                  ),
                ),
                _OrderGroup(
                  title: context.l10n.booksEstimatedFees,
                  explanation: context.l10n.booksEstimatedFeesBody,
                  icon: AppIconConstant.receiptLong,
                  orders: gaps.estimatedFees,
                  first: true,
                ),
                _OrderGroup(
                  title: context.l10n.booksUnknownCost,
                  explanation: context.l10n.booksUnknownCostBody,
                  icon: AppIconConstant.calculate,
                  orders: gaps.unknownCost,
                ),
                _OrderGroup(
                  title: context.l10n.booksUnpaidPayouts,
                  explanation: context.l10n.booksUnpaidPayoutsBody,
                  icon: AppIconConstant.payments,
                  orders: gaps.unpaidPayouts,
                ),
                _PurchaseGroup(purchases: gaps.receiptlessPurchases),
                SizedBox(height: SdContentPaddingV3.bottomGap),
              ],
            ),
    );
  }
}
