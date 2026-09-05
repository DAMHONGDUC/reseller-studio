import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_row_chevron.dart';
import '../../../domain/entities/marketplace.dart';
import '../../../providers.dart';

/// The places this business sells and the fee estimate each one uses.
///
/// The list only navigates. Adding and changing a marketplace share the detail
/// form, so the name and rate always save together.
class MarketplacesScreen extends ConsumerWidget {
  const MarketplacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Marketplace>> source = ref.watch(
      marketplacesProvider,
    );
    final List<Marketplace> marketplaces = <Marketplace>[
      for (final Marketplace marketplace
          in source.value ?? const <Marketplace>[])
        if (!marketplace.isDeleted) marketplace,
    ];

    return AppAddFabScaffold(
      appBar: SdAppBarV3(title: context.l10n.marketplacesTitle),
      addLabel: context.l10n.marketplaceAdd,
      onAdd: () => context.push(AppRoutes.addMarketplace),
      body: switch (source) {
        AsyncLoading<List<Marketplace>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        _ when marketplaces.isEmpty => SdEmptyStateV3(
          icon: AppIconConstant.storefront,
          title: context.l10n.marketplacesEmptyTitle,
          message: context.l10n.marketplacesEmptyBody,
          action: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.marketplaceAdd,
            onPressed: () => context.push(AppRoutes.addMarketplace),
          ),
        ),
        _ => ListView(
          padding: AppAddFabScaffold.listPadding(context),
          children: <Widget>[
            SizedBox(height: SdContentPaddingV3.topGap),
            AppListCard(
              children: marketplaces
                  .map(
                    (Marketplace marketplace) => AppListRow(
                      title: marketplace.name,
                      subtitle: context.l10n.marketplacesEstimatedFee,
                      icon: AppIconConstant.storefront,
                      // The colour is picked on the detail screen; this is
                      // where the seller sees what they picked.
                      iconTint: marketplace.hue.of(context),
                      // The record carries a name and a colour; what the
                      // platform charges is measured per order (hard rule 3),
                      // so there is no rate to badge here.
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // The chevron comes back by hand: a row that hands
                          // in its own trailing widget loses the one
                          // `AppListRow` would have drawn, and this row still
                          // opens a screen.
                          const AppRowChevron(),
                        ],
                      ),
                      onTap: () =>
                          context.push(AppRoutes.marketplace(marketplace.id)),
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
