part of 'cross_list_screen.dart';

/// What each platform takes, before anything is published.
///
/// **Estimates, and the panel says so.** `Marketplace.estimatedFeeRate` is a
/// planning figure — real fees vary by category, seller tier and country, and
/// the actual number arrives on the order. It is here because the decision
/// being made is "which of these is worth the fee", and a seller who cannot
/// see that is choosing blind.
///
/// Empty until something is chosen: a review of nothing is a heading with a
/// blank under it.
class _Review extends ConsumerWidget {
  const _Review();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CrossListState state = ref.watch(crossListControllerProvider);
    final Money? price = state.price;

    if (state.selected.isEmpty || price == null) {
      return const SizedBox.shrink();
    }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final Marketplace marketplace in state.selected)
                _ReviewRow(marketplace: marketplace, price: price),
              SizedBox(height: SdSpacingConstant.h8),
              Text(
                context.l10n.crossListFeesEstimated,
                style: context.textTheme3.bodySmall!.muted3(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One platform: what it takes, and what is left.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.marketplace, required this.price});

  final Marketplace marketplace;
  final Money price;

  @override
  Widget build(BuildContext context) {
    final Money fee = price.applyRate(marketplace.estimatedFeeRate);

    return Padding(
      padding: EdgeInsets.only(bottom: SdSpacingConstant.h8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              marketplace.displayName,
              style: context.textTheme3.bodyMedium!.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
            ),
          ),
          Text(
            context.l10n.crossListAfterFees(
              context.money(fee),
              context.money(price - fee),
            ),
            style: context.textTheme3.bodySmall!.muted3(context),
          ),
        ],
      ),
    );
  }
}
