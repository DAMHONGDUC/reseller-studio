part of 'subscription_screen.dart';

/// One tier, what it holds, and the buttons that buy it.
///
/// **The seller's current tier draws with no buttons at all**, rather than
/// disabled ones. A greyed-out "Buy" on the plan you already pay for reads as
/// something being broken.
class _PlanCard extends ConsumerWidget {
  const _PlanCard({
    required this.plan,
    required this.currentPlan,
    required this.offerings,
    required this.isBusy,
  });

  final SellerPlan plan;
  final SellerPlan currentPlan;

  /// The prices for this tier, monthly and yearly. Empty when billing is not
  /// configured — the card still renders, because what a plan *includes* is
  /// worth reading even when it cannot be bought yet.
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

      if (!context.mounted) return;

      // Unchanged means the seller closed the store's sheet. That is not a
      // failure and says nothing (the same rule sign-in follows).
      if (!status.plan.isAtLeast(offering.plan)) return;

      SdSnackBarUtilsV3.success(
        context,
        '${SubscriptionLabels.name(status.plan)} is active',
      );
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isCurrent = plan == currentPlan;

    return SdCardV3(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  SubscriptionLabels.name(plan),
                  style: context.textTheme3.titleMedium!.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
              ),
              if (isCurrent)
                const SdBadgeV3(
                  label: 'Your plan',
                  tone: SdBadgeToneV3.info,
                ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h8),
          for (final String line in SubscriptionLabels.allowances(plan))
            Padding(
              padding: EdgeInsets.only(bottom: SdSpacingConstant.h4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SdIconV3(
                    Symbols.check_rounded,
                    size: SdIconV3.smallSize,
                    color: context.sdTheme3.success,
                  ),
                  SizedBox(width: SdSpacingConstant.w8),
                  Expanded(
                    child: Text(
                      line,
                      style: context.textTheme3.bodyMedium!.copyWith(
                        color: context.sdTheme3.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!isCurrent && offerings.isNotEmpty) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h12),
            for (final PlanOffering offering in offerings)
              Padding(
                padding: EdgeInsets.only(bottom: SdSpacingConstant.h8),
                child: SdButtonV3(
                  // Yearly leads, because it is the one worth choosing and a
                  // grid of identical buttons makes the seller do the maths.
                  variant: offering.period == BillingPeriod.yearly
                      ? SdButtonVariantV3.primary
                      : SdButtonVariantV3.outlined,
                  label:
                      '${offering.formattedPrice} '
                      '${SubscriptionLabels.period(offering.period)}',
                  expand: true,
                  busy: isBusy,
                  onPressed: () => _buy(context, ref, offering),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
