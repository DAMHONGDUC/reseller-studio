part of 'paywall_screen.dart';

/// Fixed below the paywall's scrolling product content.
class _PaywallFooter extends ConsumerWidget {
  const _PaywallFooter();

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    try {
      final SubscriptionStatus status = await ref
          .read(subscriptionControllerProvider.notifier)
          .restore();

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(
        context,
        status.plan.isPaid
            ? context.l10n.subscriptionPlanRestored(
                SubscriptionLabels.name(status.plan),
              )
            : context.l10n.subscriptionNothingToRestore,
      );

      if (status.plan.isPaid) Navigator.of(context).pop();
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
    final bool isBusy = ref.watch(subscriptionControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SdButtonV3(
          variant: SdButtonVariantV3.text,
          label: context.l10n.subscriptionRestorePurchases,
          expand: true,
          busy: isBusy,
          onPressed: () => _restore(context, ref),
        ),
        PaywallLegalLinks(
          termsUrl: AppEnv.termsOfServiceUrl,
          privacyUrl: AppEnv.privacyPolicyUrl,
        ),
      ],
    );
  }
}
