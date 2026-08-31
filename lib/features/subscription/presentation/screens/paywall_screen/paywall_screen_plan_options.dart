part of 'paywall_screen.dart';

/// The billing periods side by side. The button that buys the selected one is
/// pinned below the scroll — `_PaywallPurchaseAction`.
class _PaywallPlanOptions extends ConsumerWidget {
  const _PaywallPlanOptions({required this.offerings});

  final List<PlanOffering> offerings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BillingPeriod period = ref.watch(paywallSelectionProvider);
    final PlanOffering? selected = PlanOfferingCatalogue.selected(
      offerings,
      period,
    );

    // The cards carry different content — one of them wears the badge — and
    // two option cards of different heights read as a layout bug.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int index = 0; index < offerings.length; index++) ...<Widget>[
            if (index > 0) SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: _PaywallPlanOption(
                offering: offerings[index],
                isSelected: offerings[index].period == selected?.period,
                isBestValue: PlanOfferingCatalogue.isBestValue(
                  offerings[index],
                  offerings,
                ),
                onSelected: () => ref
                    .read(paywallSelectionProvider.notifier)
                    .select(offerings[index].period),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One billing period, as a card the seller picks.
///
/// **Selection is a border, a filled mark and — on the recommended one — a
/// badge.** Colour is never the only signal, so the chosen card also swaps its
/// radio for a check.
class _PaywallPlanOption extends StatelessWidget {
  const _PaywallPlanOption({
    required this.offering,
    required this.isSelected,
    required this.isBestValue,
    required this.onSelected,
  });

  final PlanOffering offering;
  final bool isSelected;
  final bool isBestValue;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final PlanIntroOffer? intro = offering.introOffer;
    final String? trial = intro != null && intro.isFree
        ? context.l10n.paywallTrialTag(intro.duration(context))
        : null;

    return SdCardV3(
      layer: SdCardLayerV3.elevated,
      padding: EdgeInsets.all(SdSpacingConstant.w12),
      borderColor: isSelected ? context.colorScheme3.primary : null,
      onTap: onSelected,
      semanticLabel:
          '${SubscriptionLabels.periodName(offering.period)}, '
          '${offering.formattedPrice} ${SubscriptionLabels.period(offering.period)}'
          '${trial == null ? '' : ', $trial'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  SubscriptionLabels.periodName(offering.period),
                  style: context.textTheme3.labelLarge!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
              ),
              SdIconV3(
                isSelected
                    ? AppIconConstant.checkCircle
                    : AppIconConstant.radioButtonUnchecked,
                size: SdIconV3.smallSize,
                color: isSelected
                    ? context.colorScheme3.primary
                    : context.sdTheme3.textTertiary,
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            offering.formattedPrice,
            style: context.textTheme3.titleMedium!.semiBold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
          Text(
            SubscriptionLabels.period(offering.period),
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          if (trial != null)
            Text(
              trial,
              style: context.textTheme3.bodySmall!.semiBold3.copyWith(
                color: context.colorScheme3.primary,
              ),
            ),
          if (isBestValue) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h8),
            const SdBadgeV3(
              label: SubscriptionLabels.bestValue,
              tone: SdBadgeToneV3.success,
              size: SdBadgeSizeV3.compact,
            ),
          ],
        ],
      ),
    );
  }
}
