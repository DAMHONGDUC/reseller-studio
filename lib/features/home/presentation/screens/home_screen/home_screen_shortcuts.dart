part of 'home_screen.dart';

/// The three ways out of Home, first on the screen.
///
/// **Cards, not rows** — owner's rule. Three across is one glance, and side by
/// side they read as a choice between destinations rather than as the start of
/// a list the seller has to scan. Quick Access stays rows at the bottom for
/// the opposite reason: nine of anything is a list.
class _HomeShortcuts extends StatelessWidget {
  const _HomeShortcuts({required this.onQuickAction});

  /// Quick Access is on this screen, so its card scrolls rather than
  /// navigates — and the screen owns the controller, not this widget.
  final VoidCallback onQuickAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
    // - stretch, so a label that wraps lifts all three cards together
    // - IntrinsicHeight, because stretching inside a list means no height yet
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < HomeShortcutConstant.shortcuts.length; i++) ...<
            Widget
          >[
            if (i > 0) SizedBox(width: SdContentPaddingV3.listItemGap),
            Expanded(
              child: _HomeShortcutCard(
                shortcut: HomeShortcutConstant.shortcuts[i],
                onQuickAction: onQuickAction,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// One shortcut: a tinted glyph over its label.
class _HomeShortcutCard extends StatelessWidget {
  const _HomeShortcutCard({required this.shortcut, required this.onQuickAction});

  final HomeShortcut shortcut;
  final VoidCallback onQuickAction;

  @override
  Widget build(BuildContext context) {
    final String label = HomeShortcutLabel.of(context, shortcut.kind);

    return SdCardV3(
      padding: SdContentPaddingV3.row,
      onTap: () => _open(context),
      semanticLabel: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SdIconTileV3(icon: shortcut.icon, tint: context.colorScheme3.primary),
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            label,
            style: context.textTheme3.bodySmall!.semiBold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// `push` for search because it sits outside the shell and comes back here;
  /// `go` for Analytics because it is a tab, and pushing a branch root over
  /// Home would leave the seller on the wrong tab with a back button.
  void _open(BuildContext context) {
    switch (shortcut.kind) {
      case HomeShortcutKind.quickAction:
        onQuickAction();
      case HomeShortcutKind.search:
        context.push(AppRoutes.search);
      case HomeShortcutKind.analytics:
        context.go(AppRoutes.analytics);
    }
  }
}
