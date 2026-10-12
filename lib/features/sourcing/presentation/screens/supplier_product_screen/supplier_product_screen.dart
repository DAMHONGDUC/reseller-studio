import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/state/form_seed.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/utils/text_input_utils.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/app_section.dart';
import '../../../../../core/widgets/money_field.dart';
import '../../../../../core/widgets/price_entry_sheet.dart';
import '../../../../listings/domain/services/supplier_text_cleaner.dart';
import '../../../../orders/providers.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/supplier_product.dart';
import '../../../domain/services/supplier_cost.dart';
import '../../../providers.dart';
import '../../controllers/supplier_product_controller.dart';

part 'supplier_product_screen_fields.dart';
part 'supplier_product_screen_status.dart';

/// Add or edit one supplier product, and list it as a dropship item
/// (`docs/DROPSHIPPING_PLAN.md`). Only the title is required (hard rule 2).
class SupplierProductScreen extends ConsumerStatefulWidget {
  const SupplierProductScreen({
    required this.sourceId,
    this.productId,
    super.key,
  });

  final String sourceId;
  final String? productId;

  @override
  ConsumerState<SupplierProductScreen> createState() =>
      _SupplierProductScreenState();
}

class _SupplierProductScreenState extends ConsumerState<SupplierProductScreen>
    with FormSeed<SupplierProductScreen> {
  final _ProductFields _fields = _ProductFields();
  late final String _id = widget.productId ?? SdId.unique();

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;
      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  Future<void> _save(SupplierProduct? existing, String currency) {
    final NavigatorState navigator = Navigator.of(context);

    return _guard(() async {
      await ref
          .read(supplierProductControllerProvider.notifier)
          .save(_fields.toProduct(_id, widget.sourceId, existing, currency));
      if (mounted) navigator.pop();
    });
  }

  Future<void> _listIt(SupplierProduct product) => _guard(() async {
    final String itemId = await ref
        .read(supplierProductControllerProvider.notifier)
        .listIt(product);

    if (mounted) await context.push(AppRoutes.crossList(itemId));
  });

  /// A sample is bought at the supplier and costed as an expense.
  Future<void> _orderSample(SupplierProduct product) => PriceEntrySheet.show(
    context,
    title: context.l10n.supplierProductOrderSample,
    fieldLabel: context.l10n.supplierProductSampleCost,
    submitLabel: context.l10n.actionSave,
    initialPrice: SupplierCost.landed(product),
    helperText: context.l10n.supplierProductSampleHelp,
    onSubmit: (Money cost) async {
      await ref
          .read(supplierOrderControllerProvider.notifier)
          .orderSample(
            product: product,
            cost: cost,
            supplierName: ref.read(sourceNamesProvider)[product.sourceId],
          );
      if (mounted) {
        SdSnackBarUtilsV3.success(
          context,
          context.l10n.supplierProductSampleDone,
        );
      }
    },
  );

  Future<void> _delete(String productId) {
    final NavigatorState navigator = Navigator.of(context);

    return _guard(() async {
      await ref
          .read(supplierProductControllerProvider.notifier)
          .delete(productId);
      if (mounted) navigator.pop();
    });
  }

  Future<void> _confirmDelete(String productId) => showSdDialogV3(
    context,
    SdDialogV3(
      title: context.l10n.supplierProductDeleteTitle,
      message: context.l10n.supplierProductDeleteBody,
      icon: AppIconConstant.warning,
      actions: <SdDialogActionV3>[
        SdDialogActionV3(
          label: context.l10n.actionDelete,
          isDestructive: true,
          onPressed: () => _delete(productId),
        ),
        SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bool isSaving = ref.watch(supplierProductControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);
    final String? id = widget.productId;
    final SupplierProduct? existing = id == null
        ? null
        : ref
              .watch(activeSupplierProductsProvider)
              .where((SupplierProduct product) => product.id == id)
              .firstOrNull;

    if (existing != null) seedOnce(() => _fields.seed(existing));

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: id == null
            ? context.l10n.supplierProductAdd
            : context.l10n.supplierProductEditTitle,
        actions: <Widget>[
          if (existing != null)
            SdAppBarActionButtonV3(
              icon: AppIconConstant.delete,
              tooltip: context.l10n.actionDelete,
              tint: context.sdTheme3.danger,
              onPressed: isSaving ? null : () => _confirmDelete(existing.id),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                if (existing != null) ...<Widget>[
                  _StatusCard(
                    product: existing,
                    isBusy: isSaving,
                    onListIt: () => _listIt(existing),
                    onOpenItem: () =>
                        context.push(AppRoutes.item(existing.itemId!)),
                    onChecked: () => _guard(
                      () => ref
                          .read(supplierProductControllerProvider.notifier)
                          .markChecked(existing),
                    ),
                    onSample: () => _orderSample(existing),
                  ),
                  SizedBox(height: SdContentPaddingV3.sectionGap),
                ],
                _FieldsForm(
                  fields: _fields,
                  currency: currency,
                  onChanged: () => setState(() {}),
                ),
                SizedBox(height: SdContentPaddingV3.listItemGap),
              ],
            ),
          ),
          AppPinnedAction(
            label: context.l10n.actionSave,
            isBusy: isSaving,
            onPressed: !isSaving && _fields.title.text.trim().isNotEmpty
                ? () => _save(existing, currency)
                : null,
          ),
        ],
      ),
    );
  }
}
