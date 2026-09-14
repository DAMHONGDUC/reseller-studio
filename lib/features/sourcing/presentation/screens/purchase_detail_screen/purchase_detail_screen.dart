import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../domain/entities/purchase.dart';
import '../../../providers.dart';
import '../../controllers/sourcing_controller.dart';

/// One buying trip, and everything bought on it (plan §11).
///
/// **The gap between the receipt total and the sum of the item costs is shown,
/// not hidden.** A $40 box lot yielding eleven items is apportioned by
/// judgement, and the two figures legitimately disagree — a screen that
/// silently reconciled them would be rewriting what the seller actually paid.
class PurchaseDetailScreen extends ConsumerWidget {
  const PurchaseDetailScreen({required this.purchaseId, super.key});

  final String purchaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Purchase> purchases =
        ref.watch(purchasesProvider).value ?? const <Purchase>[];
    final Purchase? purchase = purchases
        .where((Purchase row) => row.id == purchaseId)
        .firstOrNull;

    if (purchase == null) {
      return SdScaffoldV3(
        appBar: SdAppBarV3(title: context.l10n.workflowPurchase),
        body: SdEmptyStateV3(
          icon: AppIconConstant.searchOff,
          title: context.l10n.sourcingPurchaseNotFound,
          message: context.l10n.commonMayHaveBeenDeleted,
        ),
      );
    }

    final List<Item> items =
        ref.watch(itemsForPurchaseProvider(purchaseId)).value ?? const <Item>[];

    final Money? apportioned = items
        .map((Item item) => item.purchasePrice)
        .totalOfKnown();

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: DateTimeUtils.mediumDate(
          purchase.purchaseDate,
          locale: context.localeTag,
        ),
        subtitle: ref.watch(sourceNamesProvider)[purchase.sourceId],
      ),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          Row(
            children: <Widget>[
              Expanded(
                child: SdStatTileV3(
                  label: context.l10n.sourcingReceiptTotal,
                  value: context.money(purchase.totalCost),
                  icon: AppIconConstant.receipt,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: SdStatTileV3(
                  label: context.l10n.sourcingApportioned,
                  value: context.money(apportioned),
                  caption: '${items.length} items',
                  icon: AppIconConstant.function,
                ),
              ),
            ],
          ),
          if (purchase.totalCost != null && apportioned != null) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h12),
            _ApportionmentNote(gap: purchase.totalCost! - apportioned),
          ],
          if (purchase.totalCost != null && items.isNotEmpty) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h12),
            _ApportionButton(total: purchase.totalCost!, items: items),
          ],
          if (purchase.notes != null) ...<Widget>[
            SizedBox(height: SdContentPaddingV3.sectionGap),
            SdCardV3(
              child: Text(
                purchase.notes!,
                style: context.textTheme3.bodyMedium!.muted3(context),
              ),
            ),
          ],
          SizedBox(height: SdContentPaddingV3.sectionGap),
          Text(
            context.l10n.commonItems,
            style: context.textTheme3.titleSmall!.semiBold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          if (items.isEmpty)
            SdCardV3(
              child: Text(
                context.l10n.sourcingNothingIsLinkedToThisPurchase,
                style: context.textTheme3.bodyMedium!.muted3(context),
              ),
            )
          else
            AppListCard(
              children: items
                  .map(
                    (Item item) => AppListRow(
                      title: item.title,
                      subtitle: item.status.name,
                      trailingText: context.money(item.purchasePrice),
                      onTap: () => context.push(AppRoutes.item(item.id)),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

/// Writes each linked item its share of the receipt.
///
/// **The one place a cost is apportioned rather than measured**, and it says
/// so: the receipt stays the fact, and this is the seller deciding which item
/// carried how much of it. A box lot of twelve is otherwise twelve trips to
/// twelve item forms, which is why nobody did it.
class _ApportionButton extends ConsumerWidget {
  const _ApportionButton({required this.total, required this.items});

  final Money total;
  final List<Item> items;

  Future<void> _apportion(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(sourcingControllerProvider.notifier)
          .apportion(items, total);

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(
        context,
        context.l10n.sourcingApportionDone(items.length),
      );
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isBusy = ref.watch(sourcingControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdButtonV3(
          variant: SdButtonVariantV3.secondary,
          label: context.l10n.sourcingApportionAction,
          busy: isBusy,
          expand: true,
          onPressed: isBusy ? null : () => _apportion(context, ref),
        ),
        SizedBox(height: SdSpacingConstant.h6),
        Text(
          context.l10n.sourcingApportionHelp,
          style: context.textTheme3.bodySmall!.faint3(context),
        ),
      ],
    );
  }
}

/// Says out loud whether the item costs add up to the receipt.
class _ApportionmentNote extends StatelessWidget {
  const _ApportionmentNote({required this.gap});

  /// Receipt total minus what has been apportioned. Positive means there is
  /// cost still to spread across items.
  final Money gap;

  @override
  Widget build(BuildContext context) {
    if (gap.isZero) {
      return SdCardV3(
        child: Text(
          context.l10n.sourcingEveryPennyOfThisReceiptIs,
          style: context.textTheme3.bodySmall!.copyWith(
            color: context.sdTheme3.success,
          ),
        ),
      );
    }

    final bool isUnder = gap.isPositive;

    return SdCardV3(
      child: Text(
        isUnder
            ? '${context.money(gap)} of this receipt is not on any item yet. '
                  'Profit on the unassigned part cannot be worked out.'
            : 'The items add up to ${context.money(-gap)} more than the '
                  'receipt. One of the costs is probably wrong.',
        style: context.textTheme3.bodySmall!.copyWith(
          color: context.sdTheme3.warning,
        ),
      ),
    );
  }
}
