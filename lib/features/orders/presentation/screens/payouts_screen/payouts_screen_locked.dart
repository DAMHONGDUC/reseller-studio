part of 'payouts_screen.dart';

/// What the seller is owed, and the one thing Free will not do about it.
///
/// **It names the amount.** A locked screen that says only "upgrade to see
/// this" is one nobody opens twice, and the whole argument for paying is a
/// number: a payout that never arrived is money the seller already earned.
/// So the figure stays free and the chase is what Premium buys — the per-order
/// breakdown that turns "you are owed something" into a platform, a date and
/// an order id to quote at support.
class _LockedPayouts extends ConsumerWidget {
  const _LockedPayouts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Money? owed = ref.watch(overduePayoutTotalProvider);
    final int count = ref.watch(overduePayoutsProvider).length;

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.payoutsTitle),
      body: SdEmptyStateV3(
        icon: AppIconConstant.payments,
        title: count == 0
            ? context.l10n.payoutsLockedNothingOwed
            : context.l10n.payoutsLockedOwed(context.money(owed), count),
        message: context.l10n.payoutsLockedBody,
        action: SdButtonV3(
          variant: SdButtonVariantV3.primary,
          label: context.l10n.payoutsLockedUnlock,
          onPressed: () => PlanBlockSheet.show(
            context,
            block: PlanBlock.featureLocked,
            plan: ref.read(currentPlanProvider),
          ),
        ),
      ),
    );
  }
}
