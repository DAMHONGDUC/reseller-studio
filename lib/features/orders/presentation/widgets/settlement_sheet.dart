import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/order.dart';
import '../../domain/services/payout_reconciliation.dart';
import '../controllers/order_actions_controller.dart';

/// Record what the marketplace actually took and paid.
///
/// **The payout is the one stored figure that is not derived** (hard rule 3):
/// it is a fact the platform reported, and it is what a seller reconciles
/// their bank statement against. Everything else on the profit statement is
/// computed from it and the costs.
///
/// The expected figure sits above both fields so the difference is visible
/// before anything is typed — and it says when it leaned on the marketplace's
/// estimated fee rate, because a mismatch against a guess is not a missing
/// payment.
class SettleOrderSheet extends ConsumerStatefulWidget {
  const SettleOrderSheet({required this.order, super.key});

  final Order order;

  static Future<void> show(BuildContext context, Order order) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => SettleOrderSheet(order: order),
      );

  @override
  ConsumerState<SettleOrderSheet> createState() => _SettleOrderSheetState();
}

class _SettleOrderSheetState extends ConsumerState<SettleOrderSheet> {
  late final TextEditingController _fees = TextEditingController(
    text: widget.order.fees?.toInputString() ?? '',
  );

  /// Pre-filled with what the order should have paid **only when nothing is
  /// recorded yet**. A seller working down a bank statement is confirming far
  /// more often than correcting; one who reopens a settled order came to fix
  /// the number that is there, not to be shown a guess over it.
  late final TextEditingController _payout = TextEditingController(
    text:
        widget.order.payout?.toInputString() ??
        PayoutReconciliation.expected(widget.order).toInputString(),
  );

  @override
  void dispose() {
    _fees.dispose();
    _payout.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);

    try {
      await ref
          .read(orderActionsControllerProvider.notifier)
          .recordSettlement(
            widget.order,
            fees: Money.tryParse(_fees.text, currency),
            payout: Money.tryParse(_payout.text, currency),
          );

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, context.l10n.commonSaved);
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
    final String currency = ref.watch(workspaceCurrencyProvider);

    return SdBottomSheetV3(
      title: context.l10n.settleTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdStatTileV3(
            label: context.l10n.payoutsExpected,
            value: context.money(PayoutReconciliation.expected(widget.order)),
            caption: PayoutReconciliation.isEstimated(widget.order)
                ? context.l10n.payoutsFeeIsEstimated
                : context.l10n.payoutsFeeIsReported,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          MoneyField(
            label: context.l10n.orderPlatformFees,
            controller: _fees,
            currency: currency,
            helperText: context.l10n.settleFeesHelp,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          MoneyField(
            label: context.l10n.settlePayout,
            controller: _payout,
            currency: currency,
            helperText: context.l10n.settlePayoutHelp,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.actionSave,
            expand: true,
            busy: isBusy,
            onPressed: isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
