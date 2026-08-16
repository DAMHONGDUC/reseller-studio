part of 'home_screen.dart';

/// Every create action in the app, one tap from where a seller starts.
///
/// **The create actions are scattered by design** — each lives on the screen
/// that owns the records it makes, behind that screen's own `SdFabV3`
/// (owner's rule). That is right for a seller already on the screen and wrong
/// for one who opened the app holding a receipt: recording an expense from
/// Home is three taps otherwise.
///
/// This does not replace those buttons and must not: it is a shortcut into
/// them, so every tile pushes the screen that owns the action rather than
/// opening a form Home would then have to know how to save.
class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
    child: SdCardV3(
      child: GridView.count(
        crossAxisCount: HomeConstant.quickAccessColumns,
        shrinkWrap: true,
        // The card is inside Home's own list, so this grid must not scroll on
        // its own — two nested scrollables on one axis is how a drag ends up
        // moving the wrong one.
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        mainAxisSpacing: SdSpacingConstant.h12,
        crossAxisSpacing: SdSpacingConstant.w8,
        childAspectRatio: HomeConstant.quickAccessTileRatio,
        children: <Widget>[
          for (final QuickAddAction action in QuickAddConstant.actions)
            _QuickAccessTile(action: action),
        ],
      ),
    ),
  );
}

/// One tile: a glyph and what it makes.
///
/// The label is not optional. Eight glyphs with no words is a memory test,
/// and "add a source" and "add a category" have no icon a seller would tell
/// apart at 24 points.
class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.action});

  final QuickAddAction action;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: QuickAddLabel.of(context, action.kind),
    child: InkWell(
      onTap: () => context.push(action.route),
      borderRadius: SdRadiusV3.cardAll,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SdIconTileV3(icon: action.icon, tint: context.colorScheme3.primary),
          SizedBox(height: SdSpacingConstant.h6),
          Text(
            QuickAddLabel.of(context, action.kind),
            style: context.textTheme3.labelSmall!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
