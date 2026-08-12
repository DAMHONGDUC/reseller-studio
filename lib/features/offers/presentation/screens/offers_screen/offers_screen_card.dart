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

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  Future<void> _confirmAccept(BuildContext context, WidgetRef ref) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: 'Accept ${context.money(offer.amount)}?',
        message:
            'This records the sale and creates the order, so the item leaves '
            'your inventory.',
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: 'Accept',
            isPrimary: true,
            onPressed: () => _run(
              context,
              () => ref
                  .read(offerActionsControllerProvider.notifier)
                  .accept(offer),
              'Sold — the order is in Orders',
            ),
          ),
          SdDialogActionV3(
            label: context.l10n.actionCancel,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  /// How long is left, in the words a seller reacts to.
  static String? _deadline(Offer offer, DateTime now) {
    final DateTime? expires = offer.expiresAt;

    if (expires == null || !offer.needsAction) return null;

    final Duration left = expires.difference(now);

    if (left.isNegative) return 'Expired';
    if (left.inHours < 1) return 'Under an hour left';
    if (left.inHours < 24) return '${left.inHours}h left';

    return '${left.inDays}d left';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();
    final bool isBusy = ref.watch(offerActionsControllerProvider);
    final bool canAct = offer.needsAction && !offer.hasExpired(now);
    final String? deadline = _deadline(offer, now);

    final Item? item = (ref.watch(itemsProvider).value ?? const <Item>[])
        .where((Item row) => row.id == offer.itemId)
        .firstOrNull;

    final double? discount = offer.discountFrom(item?.askingPrice);

    return SdCardV3(
      onTap: () => context.push(AppRoutes.item(offer.itemId)),
      // Tinted only while it is still actionable — a closed offer is history
      // and should not keep shouting.
      borderColor: canAct && (offer.expiresAt?.difference(now).inHours ?? 99) < 24
          ? context.sdTheme3.warning
          : null,
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
                style: context.textTheme3.titleMedium!.bold3.tabular3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h6),
          Text(
            <String>[
              offer.marketplace.displayName,
              if (item?.askingPrice != null)
                'asking ${context.money(item!.askingPrice)}',
              if (discount != null)
                '${context.percent(discount)} below',
              if (offer.buyerName != null) offer.buyerName!,
            ].join(' · '),
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
          if (offer.message != null) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h6),
            Text(
              '“${offer.message}”',
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
                  icon: Symbols.schedule_rounded,
                ),
              if (offer.counterAmount != null)
                SdBadgeV3(
                  label: 'Countered ${context.money(offer.counterAmount)}',
                  icon: Symbols.reply_rounded,
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
                    label: 'Accept',
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
                    label: 'Counter',
                    size: SdButtonSizeV3.small,
                    expand: true,
                    onPressed: () => _CounterSheet.show(context, offer),
                  ),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(
                  child: SdButtonV3(
                    variant: SdButtonVariantV3.outlined,
                    label: 'Decline',
                    size: SdButtonSizeV3.small,
                    expand: true,
                    onPressed: () => _run(
                      context,
                      () => ref
                          .read(offerActionsControllerProvider.notifier)
                          .decline(offer),
                      'Declined',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
