part of 'paywall_screen.dart';

/// The purchase block: what is on sale, or why nothing is.
///
/// Three cases and not one boolean: a store that failed to answer is not a
/// store with nothing to sell, and telling a seller the second when the first
/// happened is how a paywall loses a sale to a dropped connection.
class _PaywallOfferings extends ConsumerWidget {
  const _PaywallOfferings();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref
          .watch(planOfferingsProvider)
          .when(
            loading: () => const _PaywallOfferingsLoading(),
            error: (Object error, StackTrace stackTrace) =>
                const _PaywallOfferingsError(),
            data: (List<PlanOffering> offerings) => offerings.isEmpty
                ? const _PaywallOfferingsUnavailable()
                : _PaywallPlanOptions(offerings: offerings),
          );
}

class _PaywallOfferingsLoading extends StatelessWidget {
  const _PaywallOfferingsLoading();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h32),
    child: SdLoadingV3.page(),
  );
}

/// The store did not answer. Says so, and offers the one action that can
/// change it — the failure itself is already logged by the repository.
class _PaywallOfferingsError extends ConsumerWidget {
  const _PaywallOfferingsError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: <Widget>[
      Text(
        context.l10n.paywallPlansFailed,
        style: context.textTheme3.bodySmall!.copyWith(
          color: context.sdTheme3.danger,
        ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: SdSpacingConstant.h8),
      SdButtonV3(
        variant: SdButtonVariantV3.outlined,
        size: SdButtonSizeV3.small,
        label: context.l10n.actionRetry,
        onPressed: () => ref.invalidate(planOfferingsProvider),
      ),
    ],
  );
}

/// The store answered, and sells nothing here — a build without RevenueCat
/// configured, which is this app's normal state until the owner sets it up.
class _PaywallOfferingsUnavailable extends StatelessWidget {
  const _PaywallOfferingsUnavailable();

  @override
  Widget build(BuildContext context) => Text(
    context.l10n.paywallUnavailable,
    style: context.textTheme3.bodySmall!.copyWith(
      color: context.sdTheme3.textSecondary,
    ),
    textAlign: TextAlign.center,
  );
}
