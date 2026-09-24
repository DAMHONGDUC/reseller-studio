part of 'more_screen.dart';

class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.destination,
    required this.isLast,
    required this.plan,
    required this.signedIn,
  });

  final MoreDestination destination;
  final bool isLast;
  final SellerPlan plan;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final Color foreground = destination.isBuilt
        ? context.sdTheme3.textPrimary
        : context.sdTheme3.textTertiary;
    final String? value = MoreValueLabel.of(
      context,
      destination.kind,
      plan: plan,
      signedIn: signedIn,
    );

    return Column(
      children: <Widget>[
        InkWell(
          onTap: destination.isBuilt
              ? () => context.push(destination.route)
              : null,
          child: Padding(
            padding: SdContentPaddingV3.row,
            child: Row(
              children: <Widget>[
                SdIconV3(destination.icon, color: foreground),
                SizedBox(width: SdSpacingConstant.w12),
                Expanded(
                  child: Text(
                    MoreLabel.of(context, destination.kind),
                    style: context.textTheme3.bodyLarge!.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                if (!destination.isBuilt)
                  SdBadgeV3(label: context.l10n.moreComingSoon)
                else ...<Widget>[
                  // The value sits before the chevron, never instead of it:
                  // the row still opens something, and the glyph is what says
                  // so (`docs/rules/DESIGN_SYSTEM.md`).
                  if (value != null) ...<Widget>[
                    Text(
                      value,
                      style: context.textTheme3.bodyMedium!.copyWith(
                        color: context.sdTheme3.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(width: SdSpacingConstant.w8),
                  ],
                  const AppRowChevron(),
                ],
              ],
            ),
          ),
        ),
        if (!isLast) const SdDividerV3(),
      ],
    );
  }
}
