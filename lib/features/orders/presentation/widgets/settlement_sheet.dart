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
/// **One box, and the fee falls out of it.** The sheet used to take a fee and
/// a payout, which was two doors into one fact and let them disagree; now the
/// seller copies the figure the platform already shows them and the tile above
/// says what that means the platform kept.
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
  /// **Never pre-filled with a guess** (hard rule 3). It opens on what was
  /// recorded, or empty — a seeded estimate is indistinguishable from a fact
  /// the moment it is saved.
  late final TextEditingController _payout = TextEditingController(
    text: widget.order.payout?.toInputString() ?? '',
  );

  @override
  void dispose() {
    _payout.dispose();
    super.dispose();
  }

  /// What the platform kept, for the figure in the box right now.
  Money? _feeOf(String currency) {
    final Money? typed = Money.tryParse(_payout.text, currency);

    if (typed == null) return null;

    return PayoutReconciliation.feeImpliedBy(widget.order, typed);
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);

    try {
      await ref
          .read(orderActionsControllerProvider.notifier)
          .recordSettlement(
            widget.order,
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
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdStatTileV3(
            label: context.l10n.orderPlatformFees,
            value: context.money(_feeOf(currency)),
            caption: context.l10n.settleFeeImplied(
              context.money(widget.order.salePrice),
            ),
          ),
          SizedBox(height: SdSpacingConstant.h16),
          MoneyField(
            label: context.l10n.settlePayout,
            controller: _payout,
            currency: currency,
            helperText: context.l10n.settlePayoutHelp,
            // Redraws the tile above as the figure is typed: the seller is
            // checking the fee it implies, not the number they just copied.
            onChanged: (_) => setState(() {}),
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
