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
      SdSnackBarUtilsV3.error(context, 'Enter what you would accept');

      return;
    }

    try {
      await ref
          .read(offerActionsControllerProvider.notifier)
          .counter(widget.offer, amount);

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, 'Counter recorded');
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = ref.watch(offerActionsControllerProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SdBottomSheetV3(
        title: 'Counter ${context.money(widget.offer.amount)}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MoneyField(
              label: 'What you would accept',
              controller: _amount,
              currency: ref.watch(workspaceCurrencyProvider),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: SdSpacingConstant.h12),
            Text(
              'This is saved for your records. Send the counter on the '
              'marketplace itself — nothing is connected yet.',
              style: context.textTheme3.bodySmall!.faint3(context),
            ),
            SizedBox(height: SdSpacingConstant.h24),
            SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: 'Record counter',
              expand: true,
              busy: isBusy,
              onPressed: isBusy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
