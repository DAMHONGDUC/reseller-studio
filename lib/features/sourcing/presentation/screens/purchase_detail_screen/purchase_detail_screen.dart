import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../domain/entities/purchase.dart';
import '../../../providers.dart';

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
      return const SdScaffoldV3(
        appBar: SdAppBarV3(title: 'Purchase'),
        body: SdEmptyStateV3(
          icon: Symbols.search_off_rounded,
          title: 'Purchase not found',
          message: 'It may have been deleted.',
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
                  label: 'Receipt total',
                  value: context.money(purchase.totalCost),
                  icon: Symbols.receipt_rounded,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: SdStatTileV3(
                  label: 'Apportioned',
                  value: context.money(apportioned),
                  caption: '${items.length} items',
                  icon: Symbols.function_rounded,
                ),
              ),
            ],
          ),
          if (purchase.totalCost != null && apportioned != null) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h12),
            _ApportionmentNote(gap: purchase.totalCost! - apportioned),
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
            'Items',
            style: context.textTheme3.titleSmall!.semiBold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          if (items.isEmpty)
            SdCardV3(
              child: Text(
                'Nothing is linked to this purchase yet. Add items and set '
                'their purchase on the item form.',
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
          'Every penny of this receipt is on an item.',
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
