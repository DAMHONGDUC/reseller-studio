part of 'more_screen.dart';

/// One More row: icon, one-line label, an optional value, then the chevron.
///
/// Every row on More is drawn by this, destinations and General alike
/// (`lib/features/more/CLAUDE.md`), so no section looks pasted in.
class _MoreRowTile extends StatelessWidget {
  const _MoreRowTile({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.color,
    this.trailing,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  /// Icon and label together; null is the primary text colour.
  final Color? color;

  /// Replaces the chevron — a badge, or a spinner while the row works.
  final Widget? trailing;

  final bool showChevron;

  /// A cap on the value's own width, so one genuinely long value (an email)
  /// cannot push the row past its edge. [label] is the one child that gives
  /// way first — it is the only flex child, so it always absorbs whatever
  /// the end group does not use, which is what keeps the chevron flush to
  /// the row's true right edge on every row, value or none.
  static const double _valueMaxWidth = 160;

  @override
  Widget build(BuildContext context) {
    final Color foreground = color ?? context.sdTheme3.textPrimary;
    final String? shown = value;
    final Widget? end = trailing;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: SdContentPaddingV3.row,
        child: Row(
          children: <Widget>[
            SdIconV3(icon, color: foreground),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: _MoreRowLabel(label: label, color: foreground),
            ),
            // The value sits before the chevron, never instead of it
            // (`docs/rules/DESIGN_SYSTEM.md`).
            if (shown != null) ...<Widget>[
              SizedBox(width: SdSpacingConstant.w8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _valueMaxWidth),
                child: Text(
                  shown,
                  style: context.textTheme3.bodyMedium!.copyWith(
                    color: context.sdTheme3.textSecondary,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (end != null) ...<Widget>[
              SizedBox(width: SdSpacingConstant.w8),
              end,
            ] else if (showChevron) ...<Widget>[
              SizedBox(width: SdSpacingConstant.w8),
              const AppRowChevron(),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreRowLabel extends StatelessWidget {
  const _MoreRowLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: context.textTheme3.bodyLarge!.copyWith(color: color),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// A destination row: opens its screen, or reads "Soon" until it has one.
class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.destination, required this.plan});

  final MoreDestination destination;
  final SellerPlan plan;

  @override
  Widget build(BuildContext context) => _MoreRowTile(
    icon: destination.icon,
    label: MoreLabel.of(context, destination.kind),
    value: destination.isBuilt
        ? MoreValueLabel.of(context, destination.kind, plan: plan)
        : null,
    color: destination.isBuilt ? null : context.sdTheme3.textTertiary,
    trailing: destination.isBuilt
        ? null
        : SdBadgeV3(label: context.l10n.moreComingSoon),
    onTap: destination.isBuilt ? () => context.push(destination.route) : null,
  );
}
