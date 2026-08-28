part of 'cross_list_screen.dart';

/// What each platform will be listed at, what it takes, and what is left.
///
/// **Estimates, and the panel says so.** `Marketplace.estimatedFeeRate` is a
/// planning figure — real fees vary by category, seller tier and country, and
/// the actual number arrives on the order. It is here because the decision
/// being made is "which of these is worth the fee", and a seller who cannot
/// see that is choosing blind.
///
/// **It is also where a platform gets its own price** — owner's rule. The
/// number, the cut and the amount left are already on this row, so the place
/// to change the number is the row that shows what changing it does. A second
/// field per platform up beside the shared one would have been six boxes for
/// one intent (hard rule 2).
///
/// Empty until something is chosen: a review of nothing is a heading with a
/// blank under it.
class _Review extends ConsumerWidget {
  const _Review({required this.currency});

  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CrossListState state = ref.watch(crossListControllerProvider);

    if (state.selected.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.crossListReview,
          style: context.textTheme3.labelLarge!.copyWith(
            color: context.sdTheme3.textSecondary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        SdCardV3(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (final Marketplace marketplace in state.selected)
                _ReviewRow(marketplace: marketplace, currency: currency),
              Padding(
                padding: SdContentPaddingV3.row,
                child: Text(
                  context.l10n.crossListFeesEstimated,
                  style: context.textTheme3.bodySmall!.muted3(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One platform: what it is listed at, what it takes, and what is left.
///
/// Tapping opens the price sheet for this platform alone. A row with no price
/// yet is the case where the shared box is empty and this one has not been
/// filled in either — publish is off until it is.
class _ReviewRow extends ConsumerWidget {
  const _ReviewRow({required this.marketplace, required this.currency});

  final Marketplace marketplace;
  final String currency;

  Future<void> _edit(BuildContext context, WidgetRef ref, Money? price) =>
      PriceEntrySheet.show(
        context,
        title: context.l10n.crossListSetPriceFor(marketplace.displayName),
        fieldLabel: context.l10n.crossListPrice,
        submitLabel: context.l10n.actionSave,
        initialPrice: price,
        helperText: context.l10n.crossListUseShared,
        onSubmit: (Money picked) async => ref
            .read(crossListControllerProvider.notifier)
            .setPriceFor(marketplace, picked),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CrossListState state = ref.watch(crossListControllerProvider);
    final Money? price = state.priceFor(marketplace);
    final Money? fee = price?.applyRate(marketplace.estimatedFeeRate);

    return AppListRow(
      title: marketplace.displayName,
      // `—` rather than a zero when no price is known yet (hard rule 5).
      subtitle: fee == null || price == null
          ? context.l10n.crossListAfterFees(
              context.money(null),
              context.money(null),
            )
          : context.l10n.crossListAfterFees(
              context.money(fee),
              context.money(price - fee),
            ),
      trailing: _RowPrice(
        price: price,
        isOwn: state.isOverridden(marketplace),
      ),
      onTap: () => _edit(context, ref, price),
    );
  }
}

/// The figure on the right, and — when it is this platform's own — the badge
/// saying colour and position are not the only signal that it differs.
class _RowPrice extends StatelessWidget {
  const _RowPrice({required this.price, required this.isOwn});

  final Money? price;
  final bool isOwn;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (isOwn) ...<Widget>[
        SdBadgeV3(label: context.l10n.crossListPriceOwn),
        SizedBox(width: SdSpacingConstant.w8),
      ],
      Text(
        context.money(price),
        style: context.textTheme3.bodyMedium!.semiBold3.tabular3.copyWith(
          color: context.sdTheme3.textPrimary,
        ),
      ),
      SizedBox(width: SdSpacingConstant.w8),
      const AppRowChevron(),
    ],
  );
}
