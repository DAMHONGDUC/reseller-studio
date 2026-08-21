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

/// Record what a marketplace actually paid for one order (plan §8).
///
/// **Two numbers, and the second is the one that matters.** The fee is what
/// the platform took; the payout is what landed in the bank, and it is the
/// only stored figure in this app that is not derived (hard rule 3) because
/// it is a fact the platform reported rather than a calculation.
///
/// The expected figure is shown above both fields so the seller can see the
/// difference before they type — and it says when it leaned on the
/// marketplace's estimated fee rate, because a mismatch against a guess is
/// not a missing payment.
class SettlementSheet extends ConsumerStatefulWidget {
  const SettlementSheet({required this.order, super.key});

  final Order order;

  static Future<void> show(BuildContext context, Order order) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => SettlementSheet(order: order),
      );

  @override
  ConsumerState<SettlementSheet> createState() => _SettlementSheetState();
}

class _SettlementSheetState extends ConsumerState<SettlementSheet> {
  late final TextEditingController _fees = TextEditingController(
    text: widget.order.fees?.toInputString() ?? '',
  );

  /// Pre-filled with what the order should have paid, so a settlement that
  /// matched is one tap. A seller who is checking a statement is confirming
  /// far more often than they are correcting.
  late final TextEditingController _payout = TextEditingController(
    text: PayoutReconciliation.expected(widget.order).toInputString(),
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
      SdSnackBarUtilsV3.success(context, context.l10n.payoutsRecorded);
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
    final Money expected = PayoutReconciliation.expected(widget.order);

    return SdBottomSheetV3(
      title: context.l10n.payoutsRecordSettlement,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdStatTileV3(
            label: context.l10n.payoutsExpected,
            value: context.money(expected),
            caption: PayoutReconciliation.isEstimated(widget.order)
                ? context.l10n.payoutsFeeIsEstimated
                : context.l10n.payoutsFeeIsReported,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          MoneyField(
            label: context.l10n.payoutsFeesOptional,
            controller: _fees,
            currency: currency,
            helperText: context.l10n.payoutsFeesHelp,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          MoneyField(
            label: context.l10n.payoutsPaidOut,
            controller: _payout,
            currency: currency,
            helperText: context.l10n.payoutsPaidOutHelp,
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
