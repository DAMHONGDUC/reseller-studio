import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
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
class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    try {
      await PurchaseFormSheet.show(context);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Purchase>> source = ref.watch(purchasesProvider);
    final List<Purchase> purchases = source.value ?? const <Purchase>[];
    final Map<String, String> sourceNames = ref.watch(sourceNamesProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: 'Purchases',
        actions: <Widget>[
          IconButton(
            icon: const SdIconV3(Symbols.add_rounded),
            tooltip: 'New purchase',
            onPressed: () => _add(context, ref),
          ),
        ],
      ),
      body: switch (source) {
        AsyncLoading<List<Purchase>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        _ when purchases.isEmpty => SdEmptyStateV3(
          icon: Symbols.local_mall_rounded,
          title: 'No purchases yet',
          message:
              'Record a buying trip and every item you add to it traces back '
              'to what you paid.',
          action: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: 'Record a purchase',
            onPressed: () => _add(context, ref),
          ),
        ),
        _ => ListView(
          padding: SdContentPaddingV3.screen(context),
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
                        sourceNames[purchase.sourceId] ?? 'No source',
                        if (purchase.itemCount > 0)
                          '${purchase.itemCount} items',
                      ].join(' · '),
                      icon: Symbols.local_mall_rounded,
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
