part of 'offers_screen.dart';

/// Record a counter-offer.
///
/// **Recorded, not sent.** No marketplace is connected, so the app notes what
/// the seller came back with for their own records rather than claiming to
/// have replied to the buyer on eBay's behalf — and it says so on the sheet,
/// because a seller who thinks the counter was sent will wait for an answer
/// that never comes.
class _CounterSheet extends ConsumerStatefulWidget {
  const _CounterSheet({required this.offer});

  final Offer offer;

  static Future<void> show(BuildContext context, Offer offer) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => _CounterSheet(offer: offer),
      );

  @override
  ConsumerState<_CounterSheet> createState() => _CounterSheetState();
}

class _CounterSheetState extends ConsumerState<_CounterSheet> {
  final TextEditingController _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? amount = Money.tryParse(_amount.text, currency);

    if (amount == null) {
      SdSnackBarUtilsV3.error(context, context.l10n.offerCounterRequired);

      return;
    }

    try {
      await ref
          .read(offerActionsControllerProvider.notifier)
          .counter(widget.offer, amount);

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, context.l10n.offerCounterRecorded);
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
    final bool isBusy = ref.watch(offerActionsControllerProvider);

    return SdBottomSheetV3(
      title: context.l10n.offerCounterTitle(context.money(widget.offer.amount)),
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MoneyField(
            label: context.l10n.offerCounterAmount,
            isRequired: true,
            controller: _amount,
            currency: ref.watch(workspaceCurrencyProvider),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          Text(
            context.l10n.offerCounterNote,
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.offerCounterSubmit,
            expand: true,
            busy: isBusy,
            onPressed: isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
