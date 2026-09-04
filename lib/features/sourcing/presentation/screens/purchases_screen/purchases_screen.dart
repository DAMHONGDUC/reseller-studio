import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_empty_state.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../domain/entities/purchase.dart';
import '../../../providers.dart';
import '../../widgets/purchase_form_sheet.dart';

/// Purchases — every buying trip and what it cost (plan §11).
///
/// **The total shown is what left the seller's pocket**, from the receipt —
/// not the sum of the item costs. The two legitimately disagree when a box lot
/// is apportioned by judgement, and deriving the total would rewrite what was
/// actually paid.
///
/// **Opened on a source, it is that source's own screen.** A source has no
/// detail screen and does not need one: what a seller asks about a shop is
/// what they bought there, which is this list with one name on it.
class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({this.sourceId, super.key});

  /// Null for every purchase, set to show one source's.
  final String? sourceId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    try {
      await PurchaseFormSheet.show(context);
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
    final AsyncValue<List<Purchase>> source = ref.watch(purchasesProvider);
    final List<Purchase> all = source.value ?? const <Purchase>[];
    final Map<String, String> sourceNames = ref.watch(sourceNamesProvider);
    final String? filterId = sourceId;
    final List<Purchase> purchases = filterId == null
        ? all
        : all
              .where((Purchase purchase) => purchase.sourceId == filterId)
              .toList();

    return AppAddFabScaffold(
      appBar: SdAppBarV3(
        title: context.l10n.sourcingPurchases,
        // The name, not the id: a seller who arrived from an ROI row has to
        // be able to see which shop this is.
        subtitle: filterId == null ? null : sourceNames[filterId],
      ),
      addLabel: context.l10n.homeQuickRecordPurchase,
      onAdd: () => _add(context, ref),
      body: switch (source) {
        AsyncLoading<List<Purchase>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        // `hasAny` reads the unfiltered list: a business with purchases from
        // other shops has started, whatever this source shows.
        _ when purchases.isEmpty => AppListEmptyState(
          hasAny: all.isNotEmpty,
          noMatchMessage: context.l10n.purchasesNoneFromSource,
          emptyIcon: AppIconConstant.localMall,
          emptyTitle: context.l10n.sourcingNoPurchasesYet,
          emptyMessage: context.l10n.sourcingRecordABuyingTripAndEvery,
          emptyAction: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.homeQuickRecordPurchase,
            onPressed: () => _add(context, ref),
          ),
        ),
        _ => ListView(
          padding: AppAddFabScaffold.listPadding(context),
          children: <Widget>[
            SizedBox(height: SdContentPaddingV3.topGap),
            AppListCard(
              children: purchases
                  .map(
                    (Purchase purchase) => AppListRow(
                      title: DateTimeUtils.mediumDate(
                        purchase.purchaseDate,
                        locale: context.localeTag,
                      ),
                      subtitle: <String>[
                        sourceNames[purchase.sourceId] ??
                            context.l10n.purchasesNoSource,
                        if (purchase.itemCount > 0)
                          context.l10n.purchasesItemCount(purchase.itemCount),
                      ].join(' · '),
                      icon: AppIconConstant.localMall,
                      trailingText: context.money(purchase.totalCost),
                      onTap: () =>
                          context.push(AppRoutes.purchase(purchase.id)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      },
    );
  }
}
