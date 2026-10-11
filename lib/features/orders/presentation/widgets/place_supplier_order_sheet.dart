import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/text_input_utils.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../sourcing/domain/entities/supplier_product.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/order.dart';
import '../../providers.dart';

/// Record an order placed at the supplier for one sold line.
///
/// The costs open on the supplier product's own figures — what the seller
/// last saw at the supplier — and are what they confirm, because the price
/// at checkout is the fact; the product's figure was a quote.
class PlaceSupplierOrderSheet extends ConsumerStatefulWidget {
  const PlaceSupplierOrderSheet({
    required this.order,
    required this.line,
    required this.product,
    super.key,
  });

  final Order order;
  final OrderLine line;
  final SupplierProduct product;

  static Future<void> show(
    BuildContext context, {
    required Order order,
    required OrderLine line,
    required SupplierProduct product,
  }) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) =>
        PlaceSupplierOrderSheet(order: order, line: line, product: product),
  );

  @override
  ConsumerState<PlaceSupplierOrderSheet> createState() =>
      _PlaceSupplierOrderSheetState();
}

class _PlaceSupplierOrderSheetState
    extends ConsumerState<PlaceSupplierOrderSheet> {
  final TextEditingController _number = TextEditingController();
  late final TextEditingController _price = TextEditingController(
    text: widget.product.supplierPrice?.toInputString() ?? '',
  );
  late final TextEditingController _shipping = TextEditingController(
    text: widget.product.supplierShipping?.toInputString() ?? '',
  );
  late final TextEditingController _tax = TextEditingController(
    text: widget.product.supplierTax?.toInputString() ?? '',
  );

  @override
  void dispose() {
    _number.dispose();
    _price.dispose();
    _shipping.dispose();
    _tax.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);

    try {
      await ref
          .read(supplierOrderControllerProvider.notifier)
          .place(
            order: widget.order,
            line: widget.line,
            sourceId: widget.product.sourceId,
            supplierProductId: widget.product.id,
            supplierOrderNumber: TextInputUtils.orNull(_number.text),
            productCost: Money.tryParse(_price.text, currency),
            shippingCost: Money.tryParse(_shipping.text, currency),
            tax: Money.tryParse(_tax.text, currency),
          );
      if (!mounted) return;
      navigator.pop();
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;
      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = ref.watch(supplierOrderControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);
    final Widget gap = SizedBox(height: SdSpacingConstant.h16);

    return SdBottomSheetV3(
      title: context.l10n.supplierOrderPlaceTitle,
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdTextFieldV3(
            label: context.l10n.supplierOrderNumberLabel,
            controller: _number,
            textInputAction: TextInputAction.next,
          ),
          gap,
          MoneyField(
            label: context.l10n.supplierProductPriceLabel,
            controller: _price,
            currency: currency,
            helperText: context.l10n.supplierOrderCostHelp,
          ),
          gap,
          MoneyField(
            label: context.l10n.supplierProductShippingLabel,
            controller: _shipping,
            currency: currency,
          ),
          gap,
          MoneyField(
            label: context.l10n.supplierProductTaxLabel,
            controller: _tax,
            currency: currency,
            textInputAction: TextInputAction.done,
          ),
          gap,
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.supplierOrderPlaceSubmit,
            expand: true,
            busy: isBusy,
            onPressed: isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
