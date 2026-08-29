part of 'item_card.dart';

/// What state the item is in.
///
/// **The status badge and the stale badge are separate, and both can show**:
/// an item can be listed *and* stale, and collapsing that into one marker
/// would lose the fact that it is still live and still earning nothing.
class _StateBadges extends StatelessWidget {
  const _StateBadges({required this.item, required this.now});

  final Item item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    // Stale is a question about stock that went live and did not move, so it
    // asks the clock rather than the status: `listed` is not a state any more.
    final bool isStale =
        item.status.isOnHand &&
        StaleInventoryPolicy.isStale(item.listedAt, now: now);

    return Wrap(
      spacing: SdSpacingConstant.w6,
      runSpacing: SdSpacingConstant.h4,
      children: <Widget>[
        SdBadgeV3(
          label: item.status.label(context),
          color: item.status.color(context),
        ),
        if (isStale)
          SdBadgeV3(
            label: context.l10n.itemStale,
            tone: SdBadgeToneV3.warning,
            icon: AppIconConstant.hourglassBottom,
          ),
        // The grade a buyer reads first on every marketplace, and the thing
        // that explains a price a seller would otherwise have to open the
        // item to justify.
        if (item.condition != null)
          SdBadgeV3(
            label: item.condition!.label(context),
            color: item.condition!.color(context),
          ),
      ],
    );
  }
}

/// How long the item has been in its current state.
///
/// Its own line keeps status and condition easy to scan while placing this
/// quiet context directly above the marketplace count it qualifies.
class _StateAge extends StatelessWidget {
  const _StateAge({required this.item, required this.now});

  final Item item;
  final DateTime now;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: SdSpacingConstant.h8),
    child: SdBadgeV3(
      label: ItemAgeLabel.of(item, now: now),
      icon: AppIconConstant.schedule,
    ),
  );
}
