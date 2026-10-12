import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/text_input_utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/supplier_order.dart';
import '../../providers.dart';

/// The tracking number the supplier sent. Saving it ships the supplier order
/// and, while the sale is still waiting, the sale with it.
class SupplierTrackingSheet extends ConsumerStatefulWidget {
  const SupplierTrackingSheet({
    required this.supplierOrder,
    required this.order,
    super.key,
  });

  final SupplierOrder supplierOrder;
  final Order order;

  static Future<void> show(
    BuildContext context, {
    required SupplierOrder supplierOrder,
    required Order order,
  }) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) =>
        SupplierTrackingSheet(supplierOrder: supplierOrder, order: order),
  );

  @override
  ConsumerState<SupplierTrackingSheet> createState() =>
      _SupplierTrackingSheetState();
}

class _SupplierTrackingSheetState extends ConsumerState<SupplierTrackingSheet> {
  final TextEditingController _tracking = TextEditingController();
  final TextEditingController _carrier = TextEditingController();

  @override
  void dispose() {
    _tracking.dispose();
    _carrier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String tracking = _tracking.text.trim();

    if (tracking.isEmpty) return;

    try {
      await ref
          .read(supplierOrderControllerProvider.notifier)
          .addTracking(
            widget.supplierOrder,
            widget.order,
            trackingNumber: tracking,
            carrier: TextInputUtils.orNull(_carrier.text),
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

    return SdBottomSheetV3(
      title: context.l10n.supplierOrderTrackingTitle,
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdTextFieldV3(
            label: context.l10n.supplierOrderTrackingLabel,
            controller: _tracking,
            isRequired: true,
            textInputAction: TextInputAction.next,
            onChanged: (String _) => setState(() {}),
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdTextFieldV3(
            label: context.l10n.supplierOrderCarrierLabel,
            controller: _carrier,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.actionSave,
            expand: true,
            busy: isBusy,
            onPressed: isBusy || _tracking.text.trim().isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}
