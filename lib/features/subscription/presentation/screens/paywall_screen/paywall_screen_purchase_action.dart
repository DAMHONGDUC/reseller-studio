part of 'paywall_screen.dart';

/// The buy button, held out of the scroll above the footer links — the
/// pinned-action rule in `docs/rules/SCREENS.md`.
///
/// **Not `AppPinnedAction`**, and the rule says why: the sheet's own chrome
/// already pays the horizontal gutter and the home-indicator inset, so the
/// shared widget would draw both a second time. What is shared is the gap.
///
/// **It is absent, not disabled, until there is something to buy.** A store
/// that is still loading, that failed, or that sells nothing here has already
/// said so in the content above, and a dead primary button under it would be
/// the paywall's loudest element saying the least.
class _PaywallPurchaseAction extends ConsumerWidget {
  const _PaywallPurchaseAction();

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
      // Already logged by SubscriptionController.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PlanOffering> offerings =
        ref.watch(planOfferingsProvider).value ?? const <PlanOffering>[];

    if (offerings.isEmpty) return const SizedBox.shrink();

    final bool isBusy = ref.watch(subscriptionControllerProvider);
    final BillingPeriod period = ref.watch(paywallSelectionProvider);
    final PlanOffering? selected = PlanOfferingCatalogue.selected(
      offerings,
      period,
    );
    final PlanIntroOffer? trial = selected?.introOffer;

    return Padding(
      padding: EdgeInsets.only(top: SdContentPaddingV3.pinnedActionsGap),
      child: SdButtonV3(
        variant: SdButtonVariantV3.primary,
        // The button names what the tap starts: "Continue" hides a free week
        // from the one place the seller is looking.
        label: trial != null && trial.isFree
            ? context.l10n.paywallStartTrial(trial.duration(context))
            : context.l10n.paywallContinue,
        expand: true,
        busy: isBusy,
        onPressed: selected == null ? null : () => _buy(context, ref, selected),
      ),
    );
  }
}
