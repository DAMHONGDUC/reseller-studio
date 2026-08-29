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
        _ReadOnlyTag(
          label: item.status.label(context),
          color: item.status.color(context),
        ),
        if (isStale)
          _ReadOnlyTag(
            label: context.l10n.itemStale,
            color: context.sdTheme3.warning,
            icon: AppIconConstant.hourglassBottom,
          ),
        // The grade a buyer reads first on every marketplace, and the thing
        // that explains a price a seller would otherwise have to open the
        // item to justify.
        if (item.condition != null)
          _ReadOnlyTag(
            label: item.condition!.label(context),
            color: item.condition!.color(context),
          ),
      ],
    );
  }
}

/// A read-only use of the same tag primitive the item form uses.
///
/// `SdTagV3` is interactive by design; the card only reports facts, so this
/// wrapper removes pointer handling while preserving one component and one
/// height for every chip-like element on the row.
class _ReadOnlyTag extends StatelessWidget {
  const _ReadOnlyTag({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SdTagV3(
      label: label,
      color: color,
      selected: true,
      onSelected: _ignoreSelection,
      icon: icon,
    ),
  );

  static void _ignoreSelection() {}
}
