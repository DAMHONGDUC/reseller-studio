part of 'item_card.dart';

/// What state the item is in, and how long it has been in it.
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
    final bool isStale =
        item.status == ItemStatus.listed &&
        StaleInventoryPolicy.isStale(item.listedAt, now: now);

    return Wrap(
      spacing: SdSpacingConstant.w6,
      runSpacing: SdSpacingConstant.h4,
      children: <Widget>[
        SdBadgeV3(
          label: ItemStatusLabel.of(context, item.status),
          tone: ItemStatusLabel.tone(item.status),
        ),
        if (isStale)
          SdBadgeV3(
            label: context.l10n.itemStale,
            tone: SdBadgeToneV3.warning,
            icon: AppIconConstant.hourglassBottom,
          ),
        // How long it has been in that state, right after the badge that
        // names it — the two are one sentence.
        SdBadgeV3(
          label: ItemAgeLabel.of(item, now: now),
          icon: AppIconConstant.schedule,
        ),
      ],
    );
  }
}
