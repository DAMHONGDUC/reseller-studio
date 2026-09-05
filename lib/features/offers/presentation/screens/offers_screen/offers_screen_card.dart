part of 'offers_screen.dart';

/// One offer, with the three answers on it.
///
/// **The discount is spelled out.** "$22 (35% below asking)" is a decision;
/// "$22" is arithmetic the seller has to do while a clock runs, and that is
/// how offers get ignored until they lapse.
class _OfferCard extends ConsumerWidget {
  const _OfferCard({required this.offer});

  final Offer offer;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    try {
      await action();

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(context, done);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  Future<void> _confirmAccept(BuildContext context, WidgetRef ref) async {
    final PlanBlock block = ref.read(addOrderBlockProvider);

    if (block != PlanBlock.none) {
      await PlanBlockSheet.show(
        context,
        block: block,
        plan: ref.read(currentPlanProvider),
      );

      return;
    }

    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.offerAcceptTitle(context.money(offer.amount)),
        message: context.l10n.offerAcceptBody,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.offerAccept,
            isPrimary: true,
            onPressed: () => _run(
              context,
              () => ref
                  .read(offerActionsControllerProvider.notifier)
                  .accept(offer),
              context.l10n.offerAccepted,
            ),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  /// How long is left, in the words a seller reacts to.
  static String? _deadline(BuildContext context, Offer offer, DateTime now) {
    final DateTime? expires = offer.expiresAt;

    if (expires == null || !offer.needsAction) return null;

    final Duration left = expires.difference(now);

    if (left.isNegative) return context.l10n.offerFilterExpired;
    if (left.inHours < 1) return context.l10n.offerUnderAnHourLeft;
    if (left.inHours < 24) return context.l10n.offerHoursLeft(left.inHours);

    return context.l10n.offerDaysLeft(left.inDays);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = ref.watch(clockProvider).now();
    final bool isBusy = ref.watch(offerActionsControllerProvider);
    final bool canAct = offer.needsAction && !offer.hasExpired(now);
    final String? deadline = _deadline(context, offer, now);

    // What the offer is measured against is that marketplace's own listing:
    // the item carries no price of its own, and an offer made on Depop says
    // nothing about what eBay is asking.
    final Money? listed =
        (ref.watch(listingsProvider).value ?? const <Listing>[])
            .where(
              (Listing row) =>
                  row.itemId == offer.itemId &&
                  row.marketplace == offer.marketplace,
            )
            .firstOrNull
            ?.price;

    final double? discount = offer.discountFrom(listed);

    // What accepting would actually leave. The card used to answer "how far
    // below asking" and stop there, which is the arithmetic and not the
    // decision.
    final Item? item = ref.watch(itemProvider(offer.itemId)).value;
    final OfferEvaluation evaluation = OfferEvaluation.of(
      offer,
      feeRate: ref.watch(planningFeeRateProvider),
      cost: item?.purchasePrice,
      minimumPrice: item?.minimumPrice,
    );

    return SdCardV3(
      onTap: () => context.push(AppRoutes.item(offer.itemId)),
      // Tinted only while it is still actionable — a closed offer is history
      // and should not keep shouting.
      borderColor:
          canAct && (offer.expiresAt?.difference(now).inHours ?? 99) < 24
          ? context.sdTheme3.warning
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        offer.itemTitle,
                        style: context.textTheme3.bodyLarge!.semiBold3.copyWith(
                          color: context.sdTheme3.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: SdSpacingConstant.w8),
                    Text(
                      context.money(offer.amount),
                      style: context.textTheme3.titleMedium!.bold3.tabular3
                          .copyWith(color: context.sdTheme3.textPrimary),
                    ),
                  ],
                ),
                SizedBox(height: SdSpacingConstant.h6),
                Text(
                  <String>[
                    offer.marketplace.displayName,
                    if (listed != null)
                      context.l10n.offerAsking(context.money(listed)),
                    if (discount != null)
                      context.l10n.offerBelowAsking(context.percent(discount)),
                    if (offer.buyerName != null) offer.buyerName!,
                  ].join(' · '),
                  style: context.textTheme3.bodySmall!.faint3(context),
                ),
                SizedBox(height: SdSpacingConstant.h6),
                Text(
                  evaluation.isBelowFloor
                      ? context.l10n.offerBelowFloor(
                          context.money(evaluation.floor),
                        )
                      : context.l10n.offerLeaves(
                          context.money(evaluation.profit),
                        ),
                  style: context.textTheme3.bodySmall!.semiBold3.copyWith(
                    // Red only when it is actually a loss or under the
                    // seller's own line. An unknown cost is not a warning —
                    // a red line on every uncosted item is one nobody reads.
                    color: evaluation.isLoss || evaluation.isBelowFloor
                        ? context.sdTheme3.loss
                        : context.sdTheme3.textSecondary,
                  ),
                ),
                if (offer.message != null) ...<Widget>[
                  SizedBox(height: SdSpacingConstant.h6),
                  Text(
                    context.l10n.offerMessageQuote(offer.message!),
                    style: context.textTheme3.bodySmall!.muted3(context),
                  ),
                ],
                SizedBox(height: SdSpacingConstant.h8),
                Wrap(
                  spacing: SdSpacingConstant.w6,
                  runSpacing: SdSpacingConstant.h4,
                  children: <Widget>[
                    if (deadline != null)
                      SdBadgeV3(
                        label: deadline,
                        tone: SdBadgeToneV3.warning,
                        icon: AppIconConstant.schedule,
                      ),
                    if (offer.counterAmount != null)
                      SdBadgeV3(
                        label: context.l10n.offerCountered(
                          context.money(offer.counterAmount),
                        ),
                        icon: AppIconConstant.reply,
                      ),
                    if (offer.respondedAt != null)
                      SdBadgeV3(
                        label: DateTimeUtils.shortDate(
                          offer.respondedAt!,
                          locale: context.localeTag,
                        ),
                      ),
                  ],
                ),
                if (canAct) ...<Widget>[
                  SizedBox(height: SdSpacingConstant.h12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SdButtonV3(
                          variant: SdButtonVariantV3.primary,
                          label: context.l10n.offerAccept,
                          size: SdButtonSizeV3.small,
                          expand: true,
                          busy: isBusy,
                          onPressed: () => _confirmAccept(context, ref),
                        ),
                      ),
                      SizedBox(width: SdSpacingConstant.w8),
                      Expanded(
                        child: SdButtonV3(
                          variant: SdButtonVariantV3.secondary,
                          label: context.l10n.offerCounter,
                          size: SdButtonSizeV3.small,
                          expand: true,
                          onPressed: () => _CounterSheet.show(context, offer),
                        ),
                      ),
                      SizedBox(width: SdSpacingConstant.w8),
                      Expanded(
                        child: SdButtonV3(
                          variant: SdButtonVariantV3.outlined,
                          label: context.l10n.offerDecline,
                          size: SdButtonSizeV3.small,
                          expand: true,
                          onPressed: () => _run(
                            context,
                            () => ref
                                .read(offerActionsControllerProvider.notifier)
                                .decline(offer),
                            context.l10n.offerDeclined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          const AppRowChevron(),
        ],
      ),
    );
  }
}
