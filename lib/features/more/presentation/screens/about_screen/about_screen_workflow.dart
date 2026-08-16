part of 'about_screen.dart';

/// The lifecycle, drawn as a rail of connected steps.
///
/// **Vertical, not a horizontal chain.** The chain reads well in a document
/// (`CLAUDE.md` writes it on one line) and badly on a phone: nine links
/// across 390 points is either unreadable or a horizontal scroll nobody
/// discovers. Down the screen, each step gets room for the sentence that
/// says why it is there.
class _Workflow extends StatelessWidget {
  const _Workflow();

  @override
  Widget build(BuildContext context) => SdCardV3(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < WorkflowConstant.steps.length; i++)
          _WorkflowRow(
            step: WorkflowConstant.steps[i],
            isLast: i == WorkflowConstant.steps.length - 1,
          ),
        SizedBox(height: SdSpacingConstant.h8),
        Text(
          context.l10n.aboutWorkflowTapHint,
          style: context.textTheme3.bodySmall!.copyWith(
            color: context.sdTheme3.textTertiary,
          ),
        ),
      ],
    ),
  );
}

/// One step: a node on the rail, and what that step is for.
///
/// **Tapping it opens the screen that performs the step.** The diagram is a
/// way into the app rather than a picture of it — a page explaining a
/// workflow that cannot be entered from is the screen `CLAUDE.md` says will
/// be redesigned.
class _WorkflowRow extends StatelessWidget {
  const _WorkflowRow({required this.step, required this.isLast});

  final WorkflowStep step;
  final bool isLast;

  /// The rail's own dimensions — what the node *is*, not configuration about
  /// it, so they sit here rather than on a spacing class.
  static double get nodeSize => SdSpacingConstant.r36;
  static double get connectorWidth => SdSpacingConstant.w2;

  /// How far the text sits below the node's centre line, so the title's
  /// baseline reads as level with the glyph rather than with the circle's top
  /// edge.
  static double get textLead => SdSpacingConstant.h6;

  @override
  Widget build(BuildContext context) {
    final Color accent = context.colorScheme3.primary;

    return InkWell(
      onTap: () => context.push(step.route),
      borderRadius: SdRadiusV3.cardAll,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: nodeSize,
              child: Column(
                children: <Widget>[
                  Container(
                    width: nodeSize,
                    height: nodeSize,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: _nodeAlpha),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SdIconV3(
                        step.icon,
                        size: SdIconV3.smallSize,
                        color: accent,
                      ),
                    ),
                  ),
                  // The rail between this node and the next. The last step
                  // has nothing under it — the loop back to the top is said
                  // in words below the card rather than drawn as an arrow
                  // that would have to travel the whole height of it.
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: connectorWidth,
                        color: context.sdTheme3.divider,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: textLead,
                  bottom: isLast ? 0 : SdSpacingConstant.h16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      WorkflowLabel.title(context, step.kind),
                      style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                        color: context.sdTheme3.textPrimary,
                      ),
                    ),
                    SizedBox(height: SdSpacingConstant.h2),
                    Text(
                      WorkflowLabel.detail(context, step.kind),
                      style: context.textTheme3.bodySmall!.copyWith(
                        color: context.sdTheme3.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// How much accent the node carries behind its glyph.
  static const double _nodeAlpha = 0.12;
}
