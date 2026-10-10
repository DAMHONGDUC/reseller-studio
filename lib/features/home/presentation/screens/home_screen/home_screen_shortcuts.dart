part of 'home_screen.dart';

/// Add stock, Quick Action and Record sale, directly under Needs Attention.
///
/// **Tiles, not pills** — a label like "Enregistrer une vente" does not fit
/// beside its icon at a third of a phone, and a cut-off label is a content
/// bug. Icon over label lets the words take two lines without the row
/// changing shape. See [HomeShortcut].
class _HomeShortcuts extends ConsumerWidget {
  const _HomeShortcuts({required this.onQuickAction});

  /// Scrolls Home to its Quick Action section — the screen owns the scroll.
  final VoidCallback onQuickAction;

  void _open(BuildContext context, WidgetRef ref, HomeShortcut shortcut) {
    SdLogger.action(
      LogTagConstant.navigation,
      'Tap Home shortcut',
      <String, Object?>{'shortcut': shortcut.name},
    );

    switch (shortcut) {
      case HomeShortcut.addStock:
        unawaited(AddStockSheet.show(context, ref));
      case HomeShortcut.quickAction:
        onQuickAction();
      case HomeShortcut.recordSale:
        unawaited(context.push(AppRoutes.recordSale));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
    // - stretch, so a label that wraps lifts all three buttons together
    // - IntrinsicHeight, because stretching inside a list means no height yet
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final HomeShortcut shortcut in HomeShortcut.values) ...<Widget>[
            if (shortcut.index > 0)
              SizedBox(width: SdContentPaddingV3.listItemGap),
            Expanded(
              child: _HomeShortcutButton(
                shortcut: shortcut,
                isPrimary: shortcut.index == 0,
                onTap: () => _open(context, ref, shortcut),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// One shortcut: a glyph over its label.
///
/// The first is filled in the brand colour and the rest are outlined — one
/// primary per row (`lib/features/home/CLAUDE.md`).
class _HomeShortcutButton extends StatelessWidget {
  const _HomeShortcutButton({
    required this.shortcut,
    required this.isPrimary,
    required this.onTap,
  });

  final HomeShortcut shortcut;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label = shortcut.label(context);
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
          onTap: onTap,
          child: Padding(
            padding: SdContentPaddingV3.row,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SdIconV3(
                  shortcut.icon,
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
