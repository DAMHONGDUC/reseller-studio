part of 'cross_list_screen.dart';

/// Where to put it, and — on the same row — what each one costs.
///
/// **The platforms the item is already on are shown, ticked and disabled**,
/// never hidden. "Already on eBay" is the answer to the question the seller
/// came with, a missing row reads as a missing marketplace, and an empty
/// circle beside a platform the item is live on is simply wrong (owner's
/// rule).
///
/// **The price field lives under the name it belongs to** — owner's rule, and
/// it replaced a separate Review section whose rows opened a sheet to edit one
/// number. Choosing a platform and pricing it is one decision; splitting it
/// across two sections meant scrolling to find out what the tick had just
/// done.
class _Marketplaces extends ConsumerWidget {
  const _Marketplaces({required this.itemId, required this.currency});

  final String itemId;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<Marketplace> already = <Marketplace>{
      for (final Listing listing
          in ref.watch(listingsForItemProvider(itemId)).value ??
              const <Listing>[])
        listing.marketplace,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.crossListPickMarketplaces,
          style: context.textTheme3.labelLarge!.copyWith(
            color: context.sdTheme3.textSecondary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        SdCardV3(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < Marketplace.values.length; i++) ...<Widget>[
                _MarketplaceRow(
                  marketplace: Marketplace.values[i],
                  isAlreadyListed: already.contains(Marketplace.values[i]),
                  currency: currency,
                ),
                if (i != Marketplace.values.length - 1) const SdDividerV3(),
              ],
            ],
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        Text(
          context.l10n.crossListFeesEstimated,
          style: context.textTheme3.bodySmall!.muted3(context),
        ),
      ],
    );
  }
}

/// One platform: tick it, price it, and see what it takes.
///
/// Stateful because the price field is this row's own — a controller created
/// per build would lose the caret on every keystroke.
class _MarketplaceRow extends ConsumerStatefulWidget {
  const _MarketplaceRow({
    required this.marketplace,
    required this.isAlreadyListed,
    required this.currency,
  });

  final Marketplace marketplace;
  final bool isAlreadyListed;
  final String currency;

  @override
  ConsumerState<_MarketplaceRow> createState() => _MarketplaceRowState();
}

class _MarketplaceRowState extends ConsumerState<_MarketplaceRow> {
  final TextEditingController _price = TextEditingController();

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  /// Ticking seeds the field from the shared price; the controller writes the
  /// state, so the text is filled in from what the toggle just produced
  /// rather than from a second copy of the seeding rule.
  void _toggle() {
    ref.read(crossListControllerProvider.notifier).toggle(widget.marketplace);

    final Money? seeded = ref
        .read(crossListControllerProvider)
        .prices[widget.marketplace];

    _price.text = seeded?.toInputString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final CrossListState state = ref.watch(crossListControllerProvider);
    final bool isSelected = state.selected.contains(widget.marketplace);
    // An item already live there is ticked and inert: the circle says what is
    // true, and tapping cannot make a second listing on the same platform.
    final bool isTicked = isSelected || widget.isAlreadyListed;

    return Padding(
      padding: SdContentPaddingV3.row,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: widget.isAlreadyListed ? null : _toggle,
            child: Row(
              children: <Widget>[
                SdIconV3(
                  isTicked
                      ? Symbols.check_circle_rounded
                      : Symbols.radio_button_unchecked_rounded,
                  fill: isTicked ? 1 : 0,
                  color: isTicked
                      ? context.colorScheme3.primary
                      : context.sdTheme3.textSecondary,
                ),
                SizedBox(width: SdSpacingConstant.w12),
                Expanded(
                  child: Text(
                    widget.marketplace.displayName,
                    style: context.textTheme3.bodyMedium!.copyWith(
                      color: widget.isAlreadyListed
                          ? context.sdTheme3.textSecondary
                          : context.sdTheme3.textPrimary,
                    ),
                  ),
                ),
                if (widget.isAlreadyListed)
                  SdBadgeV3(label: context.l10n.crossListAlreadyListed),
              ],
            ),
          ),
          if (isSelected) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h8),
            MoneyField(
              label: context.l10n.crossListPrice,
              controller: _price,
              currency: widget.currency,
              isRequired: true,
              helperText: _AfterFees.of(
                context,
                widget.marketplace,
                state.prices[widget.marketplace],
              ),
              onChanged: (String value) => ref
                  .read(crossListControllerProvider.notifier)
                  .setPriceFor(
                    widget.marketplace,
                    Money.tryParse(value, widget.currency),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What the platform takes and what is left, as the price field's helper.
///
/// **Estimates, and the panel says so** — `Marketplace.estimatedFeeRate` is a
/// planning figure; real fees vary by category, seller tier and country, and
/// the actual number arrives on the order. It is under the field because the
/// decision being made is "is this price worth this platform's cut", and a
/// seller who cannot see the cut is choosing blind.
final class _AfterFees {
  static String of(BuildContext context, Marketplace marketplace, Money? price) {
    if (price == null) {
      // `—`, never a zero: nobody has typed a price, so nothing is known
      // about the fee either (hard rule 5).
      return context.l10n.crossListAfterFees(
        context.money(null),
        context.money(null),
      );
    }

    final Money fee = price.applyRate(marketplace.estimatedFeeRate);

    return context.l10n.crossListAfterFees(
      context.money(fee),
      context.money(price - fee),
    );
  }
}
