part of 'item_card.dart';

/// The band across the foot of the card: how many are left, what they cost,
/// and the way into what each marketplace is asking for them.
///
/// **Expected profit is not here** — owner's rule. It is a figure derived from
/// an asking price nobody has been offered yet, so on a list row it competes
/// with the two facts beside it while claiming less than either. The detail
/// screen still shows it.
///
/// **Cells across the card's full width** — owner's rule that the row be
/// harmonious, answered with a grid. Stacked as lines the figures made the
/// card tall and left the labels marooned at the far edge; side by side
/// inside the top row they were squeezed between a photo and a button. Across
/// the foot, the labels share one baseline and the figures share the next.
///
/// **The figures take equal shares; the arrow measures itself** — owner's
/// rule, reversing "spaced apart, not divided into shares". Cells that all
/// measured themselves put the gaps where the content left them, so the
/// middle one sat at a different place on every card and `Cost` shuffled
/// sideways down the list. Qty, Cost and Expected split the row between them
/// and the chevron takes only its glyph.
///
/// **The arrow is the same glyph every other card ends with** — owner's
/// rule. It is `AppRowChevron`, so it cannot come out a size or a grey of its
/// own, and its cell aligns to the end so it holds the card's right edge in
/// the same column as the chevrons on Orders and Offers.
///
/// **The expected price is here; a marketplace's asking price is not** —
/// owner's rule. What the item is *asked* for is a per-marketplace number, so
/// one figure on the row would be a price that may be true nowhere; what the
/// seller *expects* for it is one number the item carries itself, true whether
/// it is live on four platforms or none. The arrow beside it still opens the
/// screen that lists every marketplace's own.
///
/// Every amount renders `—` when unknown, which is most of the point: an item
/// added through Quick Add has none of them, and the row must say so rather
/// than imply the item was free. The count never does: how many are left is
/// always known, and it is zero once the item has gone.
class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.item, this.onMarketPrices});

  final Item item;

  /// Opens the marketplace prices. Null on a list that only displays, and
  /// while a bulk selection is open.
  final VoidCallback? onMarketPrices;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        child: _MoneyCell(
          label: context.l10n.itemQuantityShort,
          content: Text(
            item.quantityOnHand.toString(),
            style: context.textTheme3.bodyMedium!.bold3.tabular3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
        ),
      ),
      Expanded(
        child: _MoneyCell(
          label: context.l10n.itemCost,
          content: Text(
            context.money(item.purchasePrice),
            style: context.textTheme3.bodyMedium!.bold3.tabular3.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
        ),
      ),
      Expanded(
        child: _MoneyCell(
          label: context.l10n.itemExpectedShort,
          content: Text(
            context.money(item.expectedPrice),
            style: context.textTheme3.bodyMedium!.bold3.tabular3.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
        ),
      ),
      if (onMarketPrices == null)
        const SizedBox.shrink()
      // An item that has left inventory cannot be listed, so the screen the
      // arrow opens would refuse it. The labelled cell stays rather than
      // closing, which keeps Qty and Cost in one column down the whole list.
      else if (!item.status.isListable)
        _MoneyCell(
          label: context.l10n.inventoryPrice,
          content: SizedBox.square(dimension: AppRowChevron.size),
        )
      else
        _MoneyCell(
          label: context.l10n.inventoryPrice,
          content: AppRowChevron(
            semanticLabel: context.l10n.inventoryMarketPrices,
          ),
          tooltip: context.l10n.inventoryMarketPrices,
          onTap: onMarketPrices!,
        ),
    ],
  );
}
