import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../domain/entities/carrier.dart';
import '../../../providers.dart';

class CarriersScreen extends ConsumerWidget {
  const CarriersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Carrier>> source = ref.watch(carriersProvider);
    final List<Carrier> carriers = <Carrier>[
      for (final Carrier carrier in source.value ?? const <Carrier>[])
        if (!carrier.isDeleted) carrier,
    ];

    return AppAddFabScaffold(
      appBar: SdAppBarV3(title: context.l10n.carriersTitle),
      addLabel: context.l10n.carrierAdd,
      onAdd: () => context.push(AppRoutes.addCarrier),
      body: switch (source) {
        AsyncLoading<List<Carrier>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        _ when carriers.isEmpty => SdEmptyStateV3(
          icon: AppIconConstant.localShipping,
          title: context.l10n.carriersEmptyTitle,
          message: context.l10n.carriersEmptyBody,
          action: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.carrierAdd,
            onPressed: () => context.push(AppRoutes.addCarrier),
          ),
        ),
        _ => ListView(
          padding: AppAddFabScaffold.listPadding(context),
          children: <Widget>[
            SizedBox(height: SdContentPaddingV3.topGap),
            AppListCard(
              children: <Widget>[
                for (final Carrier carrier in carriers)
                  AppListRow(
                    title: carrier.name,
                    icon: AppIconConstant.localShipping,
                    onTap: () => context.push(AppRoutes.carrier(carrier.id)),
                  ),
              ],
            ),
          ],
        ),
      },
    );
  }
}
