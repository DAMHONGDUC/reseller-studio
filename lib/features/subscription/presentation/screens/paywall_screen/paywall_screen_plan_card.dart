part of 'paywall_screen.dart';

class _PaywallPlanCard extends ConsumerWidget {
  const _PaywallPlanCard({required this.offerings, required this.isBusy});

  final List<PlanOffering> offerings;
  final bool isBusy;

  Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    PlanOffering offering,
  ) async {
    try {
      final SubscriptionStatus status = await ref
          .read(subscriptionControllerProvider.notifier)
          .purchase(offering);

      if (!context.mounted || !status.plan.isAtLeast(offering.plan)) return;

      SdSnackBarUtilsV3.success(
        context,
        '${SubscriptionLabels.name(status.plan)} is active',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdCardV3(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          SubscriptionLabels.name(SellerPlan.premium),
          style: context.textTheme3.titleMedium!.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        for (final String line in SubscriptionLabels.allowances(
          SellerPlan.premium,
        ))
          Padding(
            padding: EdgeInsets.only(bottom: SdSpacingConstant.h4),
            child: Row(
              children: <Widget>[
                SdIconV3(
                  AppIconConstant.check,
                  size: SdIconV3.smallSize,
                  color: context.sdTheme3.success,
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(child: Text(line)),
              ],
            ),
          ),
        SizedBox(height: SdSpacingConstant.h12),
        for (final PlanOffering offering in offerings)
          Padding(
            padding: EdgeInsets.only(bottom: SdSpacingConstant.h8),
            child: SdButtonV3(
              variant: offering.period == BillingPeriod.yearly
                  ? SdButtonVariantV3.primary
                  : SdButtonVariantV3.outlined,
              label: context.l10n.subscriptionPriceLine(
                offering.formattedPrice,
                SubscriptionLabels.period(offering.period),
              ),
              expand: true,
              busy: isBusy,
              onPressed: () => _buy(context, ref, offering),
            ),
          ),
      ],
    ),
  );
}
