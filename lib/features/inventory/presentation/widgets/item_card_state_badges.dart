part of 'item_card.dart';

/// What state the item is in, and where it stands on the marketplaces.
///
/// **The status badge and the stale badge are separate, and both can show**:
/// an item can be listed *and* stale, and collapsing that into one marker
/// would lose the fact that it is still live and still earning nothing.
///
/// **One `Wrap`, not a badge row with the market count on its own line below**
/// — owner's rule that the card's tags be compact. Distribution is the same
/// kind of fact as the rest, so it flows with them and costs no second line.
class _StateBadges extends StatelessWidget {
  const _StateBadges({
    required this.item,
    required this.now,
    required this.listings,
  });

  final Item item;
  final DateTime now;
  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    // Stale is a question about stock that went live and did not move, so it
    // asks the clock rather than the status: `listed` is not a state any more.
    final bool isStale =
        item.status.isOnHand &&
        StaleInventoryPolicy.isStale(item.listedAt, now: now);
    final int marketCount = listings
        .map((Listing listing) => listing.marketplace)
        .toSet()
        .length;
    // An item that has left inventory is not late for anything, so silence is
    // the right answer for it rather than a red tag.
    final bool showMarkets = marketCount > 0 || item.status.isListable;

    return Wrap(
      spacing: SdSpacingConstant.w6,
      runSpacing: SdSpacingConstant.h4,
      children: <Widget>[
        _DisplayTag(
          label: item.status.label(context),
          color: item.status.color(context),
        ),
        if (isStale)
          _DisplayTag(
            label: context.l10n.itemStale,
            color: context.sdTheme3.warning,
            icon: AppIconConstant.hourglassBottom,
          ),
        // The grade a buyer reads first on every marketplace, and the thing
        // that explains a price a seller would otherwise have to open the
        // item to justify.
        if (item.condition != null)
          _DisplayTag(
            label: item.condition!.label(context),
            color: item.condition!.color(context),
          ),
        if (showMarkets) _Marketplaces(count: marketCount),
      ],
    );
  }
}

/// One read-only fact on the card, drawn as the compact display badge.
///
/// **`SdBadgeV3` at `compact`, never `SdTagV3`** — owner's rule that these be
/// smaller. The tag is the interactive picker the item form uses and carries
/// a picker's padding and border; the card only reports, so it draws the
/// marker the design system has for reporting, at the size a list row can
/// afford. `color` takes the enum's own hue, so one value is one colour on
/// the card and on the form.
class _DisplayTag extends StatelessWidget {
  const _DisplayTag({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SdBadgeV3(
    label: label,
    color: color,
    icon: icon,
    size: SdBadgeSizeV3.compact,
  );
}
