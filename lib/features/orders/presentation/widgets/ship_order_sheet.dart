import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../../core/widgets/picker_field.dart';
import '../../../carriers/domain/entities/carrier.dart';
import '../../../carriers/providers.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/order.dart';
import '../controllers/order_actions_controller.dart';

/// Ship an order (plan §8's `Pick → Pack → Label → Tracking → Shipped`).
///
/// **Nothing here is required.** Plan §29 attaches shipment information at the
/// transition, and this is that transition — but a seller who dropped a parcel
/// at the post office with no tracking still needs the order out of their
/// queue, and a form that refused would make the queue lie about what is left
/// to do.
///
/// The shipping cost is asked for here because it is the moment the seller
/// knows it, and it is the line that turns a sale price into a profit.
class ShipOrderSheet extends ConsumerStatefulWidget {
  const ShipOrderSheet({required this.order, super.key});

  final Order order;

  static Future<void> show(BuildContext context, Order order) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => ShipOrderSheet(order: order),
      );

  @override
  ConsumerState<ShipOrderSheet> createState() => _ShipOrderSheetState();
}

class _ShipOrderSheetState extends ConsumerState<ShipOrderSheet> {
  final TextEditingController _tracking = TextEditingController();
  late final TextEditingController _cost = TextEditingController(
    text: widget.order.shippingCost?.toInputString() ?? '',
  );

  String? _carrier;

  @override
  void initState() {
    super.initState();
    _carrier = widget.order.carrier;
    _tracking.text = widget.order.trackingNumber ?? '';
  }

  @override
  void dispose() {
    _tracking.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);
    final String tracking = _tracking.text.trim();

    try {
      await ref
          .read(orderActionsControllerProvider.notifier)
          .markShipped(
            widget.order,
            carrier: _carrier,
            trackingNumber: tracking.isEmpty ? null : tracking,
            shippingCost: Money.tryParse(_cost.text, currency),
          );

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, context.l10n.shipDone);
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
    final bool isBusy = ref.watch(orderActionsControllerProvider);
    final List<Carrier> carriers = ref.watch(activeCarriersProvider);

    return SdBottomSheetV3(
      title: context.l10n.shipTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PickerField(
            label: context.l10n.shipCarrierOptional,
            value: _carrier,
            onTap: () async {
              final String? picked = await OptionPickerSheet.show<String>(
                context,
                title: context.l10n.orderCarrier,
                selected: _carrier,
                options: carriers
                    .map(
                      (Carrier carrier) => PickerOption<String>(
                        value: carrier.name,
                        label: carrier.name,
                      ),
                    )
                    .toList(),
              );

              if (picked == null) return;

              setState(() => _carrier = picked);
            },
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdTextFieldV3(
            label: context.l10n.shipTrackingOptional,
            controller: _tracking,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          MoneyField(
            label: context.l10n.shipCostOptional,
            controller: _cost,
            currency: ref.watch(workspaceCurrencyProvider),
            helperText: context.l10n.shipCostHelp,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.shipSubmit,
            expand: true,
            busy: isBusy,
            onPressed: isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
