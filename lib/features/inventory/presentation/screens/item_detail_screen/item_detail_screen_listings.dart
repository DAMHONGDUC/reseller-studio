part of 'item_detail_screen.dart';

/// Every marketplace this item is live on, and what each is asking (plan §13).
///
/// **It is an editable section like the others** — owner's rule. The item
/// carries no price of its own (`lib/features/inventory/CLAUDE.md`), so the
/// number a buyer actually sees lives on the listing, and the detail screen is
/// where an existing item is edited. Sending the seller to the List screen to
/// move one number was a push and a pop for an edit every other field on this
/// screen makes in place.
///
/// **It adds no marketplace.** Putting the item somewhere new is the List
/// screen's question, and a section that both repriced and created would be a
/// second way to write a listing.
///
/// **A box per row, seeded on open.** Seeding on every open rather than once
/// per screen is what makes Cancel a restore — the same rule the item's own
/// sections follow.
class _ListingsSection extends ConsumerStatefulWidget {
  const _ListingsSection({required this.item});

  final Item item;

  @override
  ConsumerState<_ListingsSection> createState() => _ListingsSectionState();
}

class _ListingsSectionState extends ConsumerState<_ListingsSection> {
  /// One box per listing id. Kept across opens rather than rebuilt, so a
  /// rebuild mid-edit does not drop the seller's cursor.
  final Map<String, TextEditingController> _prices =
      <String, TextEditingController>{};

  @override
  void dispose() {
    for (final TextEditingController controller in _prices.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _boxFor(String listingId) =>
      _prices.putIfAbsent(listingId, TextEditingController.new);

  void _startEdit(List<Listing> listings) {
    for (final Listing listing in listings) {
      _boxFor(listing.id).text = listing.price.toInputString();
    }

    ref
        .read(itemDetailEditControllerProvider.notifier)
        .edit(ItemDetailSection.listings, widget.item);
  }

  Future<void> _save(List<Listing> listings) async {
    try {
      await ref
          .read(itemDetailEditControllerProvider.notifier)
          .saveListingPrices(
            itemId: widget.item.id,
            prices: <String, String>{
              for (final Listing listing in listings)
                listing.id: _boxFor(listing.id).text,
            },
          );
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Listing> listings =
        ref.watch(listingsForItemProvider(widget.item.id)).value ??
        const <Listing>[];
    final ItemDetailEditState edit = ref.watch(
      itemDetailEditControllerProvider,
    );
    final String currency = ref.watch(workspaceCurrencyProvider);

    // Nothing to reprice, so no Edit: the way on is the List screen, which
    // the actions sheet already offers.
    if (listings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionTitle(title: context.l10n.itemListings),
          SdCardV3(
            child: Text(
              context.l10n.itemNotListed,
              style: context.textTheme3.bodyMedium!.muted3(context),
            ),
          ),
        ],
      );
    }

    return _Section(
      section: ItemDetailSection.listings,
      title: context.l10n.itemListings,
      edit: edit,
      onEdit: (ItemDetailSection _) => _startEdit(listings),
      onCancel: ref.read(itemDetailEditControllerProvider.notifier).cancel,
      onSave: () => _save(listings),
      reading: _ListingFacts(listings: listings),
      editing: Column(
        children: <Widget>[
          for (int i = 0; i < listings.length; i++) ...<Widget>[
            if (i != 0) SizedBox(height: SdSpacingConstant.h16),
            MoneyField(
              label: listings[i].marketplace.displayName,
              controller: _boxFor(listings[i].id),
              currency: currency,
              textInputAction: i == listings.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
            ),
          ],
        ],
      ),
    );
  }
}

/// The rows as they read when nothing is open.
class _ListingFacts extends StatelessWidget {
  const _ListingFacts({required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      for (int i = 0; i < listings.length; i++) ...<Widget>[
        _ListingRow(listing: listings[i]),
        if (i != listings.length - 1) const SdDividerV3(),
      ],
    ],
  );
}
