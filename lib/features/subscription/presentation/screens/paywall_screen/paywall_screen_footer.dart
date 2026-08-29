part of 'paywall_screen.dart';

/// Fixed below the paywall's scrolling product content, and one row of links.
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
  Widget build(BuildContext context, WidgetRef ref) => PaywallFooterLinks(
    termsUrl: AppEnv.termsOfServiceUrl,
    privacyUrl: AppEnv.privacyPolicyUrl,
    isRestoring: ref.watch(subscriptionControllerProvider),
    onRestore: () => _restore(context, ref),
  );
}
