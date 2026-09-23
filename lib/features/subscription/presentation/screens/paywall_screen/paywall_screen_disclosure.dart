part of 'paywall_screen.dart';

/// The fine print, in the smallest type on the sheet: what the seller is
/// joining, and that it renews until they cancel (App Store guideline 3.1.2
/// requires the second in the binary).
///
/// A lifetime option adds a line saying it never renews, shown whatever is
/// selected so the fine print does not jump between taps.
///
/// A trial adds a line naming its length and the price it renews at — the same
/// guideline, and the half a badge alone does not satisfy. The line keeps its
/// room on the period that has no trial: the block is bottom-anchored, so a
/// paragraph coming and going with the selection dragged the prices up and
/// down the sheet on every tap.
class _PaywallDisclosure extends ConsumerWidget {
  const _PaywallDisclosure();

  /// [offering] comes from [PlanOfferingCatalogue.freeTrials], which is what
  /// makes the intro offer non-null.
  String _trialTerms(BuildContext context, PlanOffering offering) =>
      context.l10n.paywallTrialTerms(
        offering.introOffer!.duration(context),
        offering.formattedPrice,
        SubscriptionLabels.period(offering.period),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextStyle style = context.textTheme3.bodySmall!.copyWith(
      color: context.sdTheme3.textTertiary,
    );
    final List<PlanOffering> offerings =
        ref.watch(planOfferingsProvider).value ?? const <PlanOffering>[];
    final List<PlanOffering> trials = PlanOfferingCatalogue.freeTrials(
      offerings,
    );
    final PlanOffering? selected = PlanOfferingCatalogue.selected(
      offerings,
      ref.watch(paywallSelectionProvider),
    );
    final PlanIntroOffer? trial = selected?.introOffer;
    final bool sellsLifetime = offerings.any(
      (PlanOffering offering) => offering.period == BillingPeriod.lifetime,
    );
    final String? trialTerms = selected != null && trial != null && trial.isFree
        ? _trialTerms(context, selected)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (trials.isNotEmpty) ...<Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                SizedBox(
                  // Measured, not rendered: the terms of a period the seller
                  // did not pick are a promise this one does not make.
                  height: TextMeasureUtils.tallestHeight(
                    texts: <String>[
                      for (final PlanOffering offering in trials)
                        _trialTerms(context, offering),
                    ],
                    style: style,
                    maxWidth: constraints.maxWidth,
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  ),
                  child: trialTerms == null
                      ? null
                      : Text(trialTerms, style: style),
                ),
          ),
          SizedBox(height: SdSpacingConstant.h6),
        ],
        Text(context.l10n.paywallStoreAccountNote, style: style),
        SizedBox(height: SdSpacingConstant.h6),
        Text(context.l10n.subscriptionRenewalTerms, style: style),
        if (sellsLifetime) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h6),
          Text(context.l10n.paywallLifetimeTerms, style: style),
        ],
      ],
    );
  }
}
