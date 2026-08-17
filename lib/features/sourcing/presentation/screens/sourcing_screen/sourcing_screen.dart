import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/source.dart';
import '../../../providers.dart';

/// Sourcing — where stock comes from, and what it returned (plan §11).
///
/// **The hub, not a list.** Purchases, sources and the buy calculator answer
/// different questions, and the top of this screen answers the only one a
/// seller has before they pick: how much have I spent, and did it come back.
///
/// The calculator sits here rather than under a record because it is used
/// *before* there is a record — standing in a shop with the thing in hand.
class SourcingScreen extends ConsumerWidget {
  const SourcingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Purchase> purchases =
        ref.watch(purchasesProvider).value ?? const <Purchase>[];
    final List<Source> sources =
        ref.watch(sourcesProvider).value ?? const <Source>[];

    final Money? spend = purchases
        .map((Purchase purchase) => purchase.totalCost)
        .totalOfKnown();

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.moreSourcing),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          Row(
            children: <Widget>[
              Expanded(
                child: SdStatTileV3(
                  label: context.l10n.analyticsSpent,
                  value: context.money(spend, compact: true),
                  icon: Symbols.payments_rounded,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: SdStatTileV3(
                  label: context.l10n.sourcingBuyingTrips,
                  value: '${purchases.length}',
                  icon: Symbols.local_mall_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          AppListCard(
            children: <Widget>[
              AppListRow(
                title: context.l10n.sourcingPurchases,
                subtitle: context.l10n.sourcingEveryBuyingTripAndWhatIt,
                icon: Symbols.local_mall_rounded,
                onTap: () => context.push(AppRoutes.purchases),
              ),
              AppListRow(
                title: context.l10n.analyticsSources,
                subtitle: sources.isEmpty
                    ? 'Add the shops worth going back to'
                    : '${sources.length} places, ranked by what they return',
                icon: Symbols.storefront_rounded,
                onTap: () => context.push(AppRoutes.sources),
              ),
              AppListRow(
                title: context.l10n.sourcingShouldIBuyThis,
                subtitle: context.l10n.sourcingWorkOutProfitRoiAndThe,
                icon: Symbols.calculate_rounded,
                onTap: () => context.push(AppRoutes.purchaseEvaluator),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
