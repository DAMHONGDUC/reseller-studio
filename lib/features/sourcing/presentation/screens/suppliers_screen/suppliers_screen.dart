import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/name_entry_sheet.dart';
import '../../../../listings/domain/enums/listing_status.dart';
import '../../../domain/entities/source.dart';
import '../../../domain/entities/supplier_product.dart';
import '../../../providers.dart';
import '../../controllers/sourcing_controller.dart';

/// The dropship suppliers — sources that ship to the buyer for the seller
/// (`docs/DROPSHIPPING_PLAN.md`). Only a name is asked for (plan §28).
class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final String? name = await NameEntrySheet.show(
      context,
      title: context.l10n.supplierAdd,
      label: context.l10n.commonName,
      hint: context.l10n.supplierNameHint,
    );

    if (name == null || !context.mounted) return;

    try {
      await ref
          .read(sourcingControllerProvider.notifier)
          .saveSource(name: name, type: SourceType.dropshipSupplier);
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
    final AsyncValue<List<Source>> source = ref.watch(sourcesProvider);
    final List<Source> suppliers = ref.watch(suppliersProvider);
    final List<SupplierProduct> products = ref.watch(
      activeSupplierProductsProvider,
    );

    return AppAddFabScaffold(
      appBar: SdAppBarV3(title: context.l10n.suppliersTitle),
      addLabel: context.l10n.supplierAdd,
      onAdd: () => _add(context, ref),
      body: switch (source) {
        AsyncLoading<List<Source>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        _ when suppliers.isEmpty => SdEmptyStateV3(
          icon: AppIconConstant.localShipping,
          title: context.l10n.suppliersEmptyTitle,
          message: context.l10n.suppliersEmptyBody,
          action: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.supplierAdd,
            onPressed: () => _add(context, ref),
          ),
        ),
        _ => ListView(
          padding: AppAddFabScaffold.listPadding(context),
          children: <Widget>[
            SizedBox(height: SdContentPaddingV3.topGap),
            AppListCard(
              children: <Widget>[
                for (final Source supplier in suppliers)
                  _SupplierRow(
                    supplier: supplier,
                    products: <SupplierProduct>[
                      for (final SupplierProduct product in products)
                        if (product.sourceId == supplier.id) product,
                    ],
                  ),
              ],
            ),
          ],
        ),
      },
    );
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({required this.supplier, required this.products});

  final Source supplier;
  final List<SupplierProduct> products;

  @override
  Widget build(BuildContext context) {
    final int listed = products
        .where((SupplierProduct product) => product.itemId != null)
        .length;

    return AppListRow(
      title: supplier.name,
      subtitle:
          '${context.l10n.supplierProductCount(products.length)} · '
          '${context.l10n.supplierListedCount(listed)}',
      icon: AppIconConstant.localShipping,
      onTap: () => context.push(AppRoutes.supplier(supplier.id)),
    );
  }
}
