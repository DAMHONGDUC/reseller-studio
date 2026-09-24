part of 'intake_session_screen.dart';

/// What has gone in so far, newest first.
///
/// **Each row is a record, not a basket line.** The item is already written,
/// so an abandoned session still leaves everything the seller typed — which is
/// what makes it safe to keep the header, the boxes and this list on one
/// screen instead of behind a wizard.
class _TakenIn extends StatelessWidget {
  const _TakenIn({required this.state});

  final IntakeSessionState state;

  @override
  Widget build(BuildContext context) => AppSection(
    title: context.l10n.intakeTakenIn(state.count),
    first: true,
    padding: EdgeInsets.zero,
    child: Column(
      children: <Widget>[
        for (int i = 0; i < state.lines.length; i++) ...<Widget>[
          Padding(
            padding: SdContentPaddingV3.row,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    state.lines[i].title,
                    style: context.textTheme3.bodyMedium!.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                // `—` where no cost was entered, never a zero: a blank
                // box means nobody said, not that it was free.
                Text(
                  context.money(state.lines[i].cost),
                  style: context.textTheme3.bodyMedium!.tabular3.copyWith(
                    color: context.sdTheme3.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (i != state.lines.length - 1) const SdDividerV3(),
        ],
      ],
    ),
  );
}
