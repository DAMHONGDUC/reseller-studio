part of 'paywall_screen.dart';

/// The fine print, in the smallest type on the sheet: what the seller is
/// joining, and that it renews until they cancel (App Store guideline 3.1.2
/// requires the second in the binary).
///
/// A trial adds a third line naming its length and the price it renews at —
/// the same guideline, and the half a badge alone does not satisfy.
class _PaywallDisclosure extends ConsumerWidget {
  const _PaywallDisclosure();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextStyle style = context.textTheme3.bodySmall!.copyWith(
      color: context.sdTheme3.textTertiary,
    );
    final List<PlanOffering> offerings =
        ref.watch(planOfferingsProvider).value ?? const <PlanOffering>[];
    final PlanOffering? selected = PlanOfferingCatalogue.selected(
      offerings,
      ref.watch(paywallSelectionProvider),
    );
    final PlanIntroOffer? trial = selected?.introOffer;
    final String? trialTerms = selected != null && trial != null && trial.isFree
        ? context.l10n.paywallTrialTerms(
            trial.duration(context),
            selected.formattedPrice,
            SubscriptionLabels.period(selected.period),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (trialTerms != null) ...<Widget>[
          Text(trialTerms, style: style),
          SizedBox(height: SdSpacingConstant.h6),
        ],
        Text(context.l10n.paywallStoreAccountNote, style: style),
        SizedBox(height: SdSpacingConstant.h6),
        Text(context.l10n.subscriptionRenewalTerms, style: style),
      ],
    );
  }
}
