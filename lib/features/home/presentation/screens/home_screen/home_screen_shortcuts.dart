part of 'home_screen.dart';

/// The three create actions, directly under Needs Attention.
///
/// **Tiles, not pills** — a label like "Enregistrer une vente" does not fit
/// beside its icon at a third of a phone, and a cut-off label is a content
/// bug. Icon over label lets the words take two lines without the row
/// changing shape. See `HomeShortcutConstant`.
class _HomeShortcuts extends StatelessWidget {
  const _HomeShortcuts();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
    // - stretch, so a label that wraps lifts all three buttons together
    // - IntrinsicHeight, because stretching inside a list means no height yet
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (
            int i = 0;
            i < HomeShortcutConstant.shortcuts.length;
            i++
          ) ...<Widget>[
            if (i > 0) SizedBox(width: SdContentPaddingV3.listItemGap),
            Expanded(
              child: _HomeShortcutButton(
                action: HomeShortcutConstant.actionFor(
                  HomeShortcutConstant.shortcuts[i],
                ),
                isPrimary: i == 0,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// One shortcut: a glyph over its Quick Action label.
///
/// The first is filled in the brand colour and the rest are outlined — one
/// primary per row (`lib/features/home/CLAUDE.md`).
class _HomeShortcutButton extends StatelessWidget {
  const _HomeShortcutButton({required this.action, required this.isPrimary});

  final QuickAction action;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final String label = QuickActionLabel.of(context, action.kind);
    final Color background = isPrimary
        ? context.colorScheme3.primary
        : context.sdTheme3.surfaceElevated;
    final Color foreground = isPrimary
        ? context.colorScheme3.onPrimary
        : context.sdTheme3.textPrimary;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: SdRadiusV3.cardAll,
          side: isPrimary
              ? BorderSide.none
              : BorderSide(color: context.sdTheme3.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => switch (action.open) {
            QuickActionOpen.push => context.push(action.route),
            QuickActionOpen.goTab => context.go(action.route),
          },
          child: Padding(
            padding: SdContentPaddingV3.row,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SdIconV3(
                  action.icon,
                  color: isPrimary ? foreground : context.colorScheme3.primary,
                ),
                SizedBox(height: SdSpacingConstant.h6),
                Text(
                  label,
                  style: context.textTheme3.bodySmall!.semiBold3.copyWith(
                    color: foreground,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
