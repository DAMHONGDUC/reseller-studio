import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/order.dart';
import '../controllers/order_actions_controller.dart';

/// Money back to the buyer, in part or in full (plan §16).
///
/// **Partial is the case this sheet exists for.** A full refund is a status
/// change anyone would have guessed at; a £10 goodwill refund on a £100 order
/// the buyer kept is the one that goes wrong silently, because treating it as
/// a full refund erases the whole sale from every figure. The helper under
/// the field says which of the two the typed amount is, before it is saved.
///
/// The sale price sits above the field so the comparison needs no arithmetic,
/// and the shortcut fills it — a full refund is one tap, not a retyped number.
class RefundSheet extends ConsumerStatefulWidget {
  const RefundSheet({required this.order, super.key});

  final Order order;

  static Future<void> show(BuildContext context, Order order) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => RefundSheet(order: order),
      );

  @override
  ConsumerState<RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends ConsumerState<RefundSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.order.refund?.toInputString() ?? '',
  );

  Money? _typed;

  @override
  void initState() {
    super.initState();
    _typed = widget.order.refund;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _fillWholeSale() {
    final Money sale = widget.order.salePrice;

    _amount.text = sale.toInputString();
    setState(() => _typed = sale);
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final Money? amount = _typed;

    if (amount == null) return;

    try {
      await ref
          .read(orderActionsControllerProvider.notifier)
          .refund(widget.order, amount);

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, context.l10n.refundRecorded);
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  /// Which of the three things the typed amount is, in the seller's words.
  String? _helper(BuildContext context) {
    final Money? amount = _typed;

    if (amount == null) return null;
    if (amount > widget.order.salePrice) return context.l10n.refundOverHelp;

    return amount >= widget.order.salePrice
        ? context.l10n.refundFullHelp
        : context.l10n.refundPartialHelp;
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = ref.watch(orderActionsControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);
    final Money? already = widget.order.refund;
    final bool isValid =
        _typed != null &&
        _typed!.minor > 0 &&
        _typed! <= widget.order.salePrice;

    return SdBottomSheetV3(
      title: context.l10n.refundTitle,
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdStatTileV3(
            label: context.l10n.refundSoldFor,
            value: context.money(widget.order.salePrice),
            caption: already == null
                ? null
                : context.l10n.refundAlreadyRecorded(context.money(already)),
          ),
          SizedBox(height: SdSpacingConstant.h16),
          MoneyField(
            label: context.l10n.refundAmount,
            isRequired: true,
            controller: _amount,
            currency: currency,
            helperText: _helper(context),
            textInputAction: TextInputAction.done,
            onChanged: (String value) =>
                setState(() => _typed = Money.tryParse(value, currency)),
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SdButtonV3(
            variant: SdButtonVariantV3.text,
            label: context.l10n.refundWholeSale,
            onPressed: isBusy ? null : _fillWholeSale,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdButtonV3(
            variant: SdButtonVariantV3.destructive,
            label: context.l10n.refundAction,
            expand: true,
            busy: isBusy,
            onPressed: isBusy || !isValid ? null : _submit,
          ),
        ],
      ),
    );
  }
}
