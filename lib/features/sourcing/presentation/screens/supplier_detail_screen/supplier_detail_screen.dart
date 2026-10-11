import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../domain/entities/source.dart';
import '../../../domain/entities/supplier_product.dart';
import '../../../domain/services/supplier_cost.dart';
import '../../../providers.dart';

/// One supplier's products, each with what an order costs and whether it is
/// listed yet.
class SupplierDetailScreen extends ConsumerWidget {
  const SupplierDetailScreen({required this.sourceId, super.key});

  final String sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Source? supplier = ref
        .watch(suppliersProvider)
        .where((Source source) => source.id == sourceId)
        .firstOrNull;
    final List<SupplierProduct> products = ref.watch(
      supplierProductsForSourceProvider(sourceId),
    );

    return AppAddFabScaffold(
      appBar: SdAppBarV3(title: supplier?.name ?? context.l10n.suppliersTitle),
      addLabel: context.l10n.supplierProductAdd,
      onAdd: () => context.push(AppRoutes.addSupplierProduct(sourceId)),
      body: products.isEmpty
          ? SdEmptyStateV3(
              icon: AppIconConstant.addBox,
              title: context.l10n.supplierProductsEmptyTitle,
              message: context.l10n.supplierProductsEmptyBody,
              action: SdButtonV3(
                variant: SdButtonVariantV3.primary,
                label: context.l10n.supplierProductAdd,
                onPressed: () =>
                    context.push(AppRoutes.addSupplierProduct(sourceId)),
              ),
            )
          : ListView(
              padding: AppAddFabScaffold.listPadding(context),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                AppListCard(
                  children: <Widget>[
                    for (final SupplierProduct product in products)
                      _ProductRow(product: product),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final SupplierProduct product;

  @override
  Widget build(BuildContext context) {
    final int? stock = product.stock;

    return AppListRow(
      title: product.title,
      subtitle: <String>[
        if (product.itemId == null)
          context.l10n.supplierProductNotListed
        else
          context.l10n.supplierProductListed,
        if (stock != null) context.l10n.supplierProductStockValue(stock),
      ].join(' · '),
      trailingText: context.money(SupplierCost.landed(product)),
      onTap: () =>
          context.push(AppRoutes.supplierProduct(product.sourceId, product.id)),
    );
  }
}
