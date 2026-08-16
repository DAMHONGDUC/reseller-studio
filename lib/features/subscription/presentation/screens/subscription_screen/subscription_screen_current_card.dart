part of 'subscription_screen.dart';

/// What the seller is on, and the one thing about it that might need acting
/// on — a cancellation that has not lapsed, or a card that failed.
class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.plan, required this.status});

  final SellerPlan plan;

  /// Null while entitlement is still loading. The plan renders as Free in
  /// that moment (see `currentPlanProvider`), so this card shows the tier and
  /// leaves the renewal line out rather than inventing one.
  final SubscriptionStatus? status;

  @override
  Widget build(BuildContext context) {
    final SubscriptionStatus? current = status;
    final String? note = current == null ? null : _note(context, current);

    return SdCardV3(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  SubscriptionLabels.name(plan),
                  style: context.textTheme3.headlineSmall!.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
              ),
              SdBadgeV3(
                label: plan.isPaid ? 'Active' : 'Current',
                tone: plan.isPaid
                    ? SdBadgeToneV3.success
                    : SdBadgeToneV3.neutral,
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h4),
          Text(
            SubscriptionLabels.tagline(plan),
            style: context.textTheme3.bodyMedium!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          if (note != null) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h12),
            Text(
              note,
              style: context.textTheme3.bodySmall!.copyWith(
                color: current!.isInGracePeriod
                    ? context.sdTheme3.warning
                    : context.sdTheme3.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The renewal line, in priority order.
  ///
  /// A billing problem outranks a renewal date, and a cancellation outranks
  /// both — showing "renews 3 March" to someone who cancelled is the version
  /// of this that generates a support email.
  static String? _note(BuildContext context, SubscriptionStatus status) {
    if (!status.plan.isPaid) return null;

    if (status.isInGracePeriod) {
      return 'Payment failed. Your plan continues while the store retries — '
          'update your card to keep it.';
    }

    final DateTime? renews = status.renewsAt;

    if (renews == null) return null;

    final String date = DateTimeUtils.mediumDate(
      renews,
      locale: context.localeTag,
    );

    return status.willRenew ? 'Renews $date' : 'Ends $date — set not to renew';
  }
}
