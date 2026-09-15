part of 'item_form_screen.dart';

/// What the item costs on each marketplace it is live on, edited here.
///
/// **In the form, not behind a navigation** — owner's rule. Cost, asking price
/// and minimum are already on this screen; the number a buyer actually sees is
/// the one a seller most often came to change, and sending them to another
/// route for it made the form the wrong place to answer "what is this priced
/// at".
///
/// **Only listings that exist.** Adding a marketplace is a different intent
/// with its own screen (`CrossListScreen`, from the item's Actions sheet) —
/// this section changes numbers on platforms the item is already on and never
/// creates one.
///
/// The edits ride on `ItemFormState.listingPrices` and are written by the
/// form's own Save, so a seller who changes a price and a title presses one
/// button.
class _MarketplacePrices extends ConsumerWidget {
  const _MarketplacePrices({required this.itemId, required this.currency});

  final String itemId;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Listing> listings =
        ref.watch(listingsForItemProvider(itemId)).value ?? const <Listing>[];

    if (listings.isEmpty) return const SizedBox.shrink();

    // The section spaces its own children, and this whole block is one of
    // them — so the gap between these fields has to come from here, or they
    // sit flush against each other while every other field on the form has
    // air around it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < listings.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: SdSpacingConstant.h16),
          _MarketplacePriceField(listing: listings[i], currency: currency),
        ],
      ],
    );
  }
}

/// One live listing's price, labelled by the platform it is on.
///
/// Stateful for its controller: one created per build would lose the caret on
/// every keystroke.
class _MarketplacePriceField extends ConsumerStatefulWidget {
  const _MarketplacePriceField({required this.listing, required this.currency});

  final Listing listing;
  final String currency;

  @override
  ConsumerState<_MarketplacePriceField> createState() =>
      _MarketplacePriceFieldState();
}

class _MarketplacePriceFieldState
    extends ConsumerState<_MarketplacePriceField> {
  late final TextEditingController _price = TextEditingController(
    text: widget.listing.price.toInputString(),
  );

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MoneyField(
    label: widget.listing.marketplaceName,
    controller: _price,
    currency: widget.currency,
    textInputAction: TextInputAction.next,
    onChanged: (String value) => ref
        .read(itemFormControllerProvider.notifier)
        .setListingPrice(
          widget.listing.id,
          Money.tryParse(value, widget.currency),
        ),
  );
}
