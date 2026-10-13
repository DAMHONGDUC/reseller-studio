part of 'item_detail_screen.dart';

/// Item detail's bar outside edit mode.
///
/// **The item's title is on screen once** (`docs/rules/SCREENS.md`): the
/// bar reads "Item" while the summary block shows the title, and takes the
/// title once that block has scrolled away — a short cross-fade, not a jump.
class _ItemAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ItemAppBar({required this.item, required this.titleInBar});

  final Item? item;

  /// True once the summary block is out of view.
  final bool titleInBar;

  @override
  Size get preferredSize => Size.fromHeight(
    SdAppBarV3.toolbarHeight +
        (item?.sku == null ? 0 : SdAppBarV3.subtitleHeight),
  );

  @override
  Widget build(BuildContext context) {
    final Item? value = item;
    final bool showTitle = value != null && titleInBar;

    return AnimatedSwitcher(
      duration: SdMotionV3.of(context, SdMotionV3.fast),
      layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...previous, ?current],
      ),
      child: SdAppBarV3(
        key: ValueKey<bool>(showTitle),
        title: showTitle ? value.title : context.l10n.itemTitleFallback,
        subtitle: value?.sku,
        actions: <Widget>[
          if (value != null)
            AppDetailActionButton(
              label: context.l10n.commonActions,
              onPressed: () =>
                  ItemActionsSheet.show(context, value, isOnDetail: true),
            ),
        ],
      ),
    );
  }
}
