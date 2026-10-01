part of 'more_screen.dart';

/// A titled card of rows with a hairline between each.
class _MoreRowsSection extends StatelessWidget {
  const _MoreRowsSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => AppSection(
    title: title,
    padding: EdgeInsets.zero,
    child: Column(
      children: <Widget>[
        for (int index = 0; index < rows.length; index++) ...<Widget>[
          rows[index],
          if (index < rows.length - 1) const SdDividerV3(),
        ],
      ],
    ),
  );
}

/// A destination section: its title over a grid of tiles.
///
/// **Tiles, not rows** — owner's rule (`lib/features/more/CLAUDE.md`). A
/// section of places is picked from at a glance; General keeps rows because
/// its value is the point.
///
/// **Three across, not four.** At a quarter of a phone "Emplacements" or
/// "Marktplätze" breaks mid-word; a third holds every shipping locale's
/// longest label on two lines.
class _MoreSection extends StatelessWidget {
  const _MoreSection({required this.section});

  static const int _columns = 3;

  final MoreSection section;

  @override
  Widget build(BuildContext context) {
    final List<MoreDestination> destinations = section.destinations;
    final double gap = SdContentPaddingV3.listItemGap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdSectionHeaderV3(title: MoreSectionLabel.of(context, section.kind)),
        for (int start = 0; start < destinations.length; start += _columns)
          Padding(
            padding: EdgeInsets.only(top: start == 0 ? 0 : gap),
            // Stretched so a label that wraps lifts its whole row together.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = start; i < start + _columns; i++) ...<Widget>[
                    if (i > start) SizedBox(width: gap),
                    Expanded(
                      child: i < destinations.length
                          ? _MoreTile(destination: destinations[i])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One destination: a tinted glyph over its label, or a faint tile with a
/// "Soon" badge until it has a screen.
class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.destination});

  final MoreDestination destination;

  @override
  Widget build(BuildContext context) {
    final String label = MoreLabel.of(context, destination.kind);
    final bool isBuilt = destination.isBuilt;
    final Color tint = isBuilt
        ? MoreHue.of(destination.kind).of(context)
        : context.sdTheme3.textTertiary;

    return SdCardV3(
      padding: EdgeInsets.symmetric(
        horizontal: SdSpacingConstant.w8,
        vertical: SdSpacingConstant.h14,
      ),
      onTap: isBuilt ? () => context.push(destination.route) : null,
      semanticLabel: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SdIconTileV3(icon: destination.icon, tint: tint),
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            label,
            style: context.textTheme3.bodySmall!.semiBold3.copyWith(
              color: isBuilt
                  ? context.sdTheme3.textPrimary
                  : context.sdTheme3.textTertiary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isBuilt) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h4),
            SdBadgeV3(
              label: context.l10n.moreComingSoon,
              size: SdBadgeSizeV3.compact,
            ),
          ],
        ],
      ),
    );
  }
}
