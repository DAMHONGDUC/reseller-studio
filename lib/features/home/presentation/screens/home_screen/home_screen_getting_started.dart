part of 'home_screen.dart';

/// The three first moves, ticked off as the seller makes them.
///
/// **It is a progress report, not a second `_StartHere`.** The card in Needs
/// Attention names the one next action and carries a button; this names the
/// whole short path and says how far along it is, which is the question a
/// seller who has added two items but sold nothing is actually asking.
///
/// **It removes itself.** Once all three are done the section is gone for
/// good, header included — no dismiss control to build, and nothing for an
/// established seller to keep scrolling past. That is also why it never
/// renders while a source is still loading: see `gettingStartedProvider`.
class _GettingStarted extends ConsumerWidget {
  const _GettingStarted();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<GettingStartedStep>? done = ref.watch(gettingStartedProvider);
    final List<GettingStartedStep> steps = GettingStartedStep.values;

    if (done == null || done.length == steps.length) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdSectionHeaderV3(
          title: context.l10n.homeGettingStarted,
          subtitle: context.l10n.homeGettingStartedProgress(
            done.length,
            steps.length,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdContentPaddingV3.horizontal,
          ),
          child: AppListCard(
            children: <Widget>[
              for (int i = 0; i < steps.length; i++) ...<Widget>[
                if (i > 0) const SdDividerV3(),
                _GettingStartedRow(
                  step: steps[i],
                  isDone: done.contains(steps[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One step: what it is, and — until it is done — the way to do it.
class _GettingStartedRow extends StatelessWidget {
  const _GettingStartedRow({required this.step, required this.isDone});

  final GettingStartedStep step;
  final bool isDone;

  @override
  Widget build(BuildContext context) => AppListRow(
    title: GettingStartedStepLabel.title(context, step),
    subtitle: GettingStartedStepLabel.detail(context, step),
    icon: isDone
        ? Symbols.check_circle_rounded
        : GettingStartedStepLabel.icon(step),
    iconTint: isDone ? context.sdTheme3.success : null,
    // A finished step is a record, and a chevron on it is an affordance that
    // leads nowhere.
    showChevron: !isDone,
    onTap: isDone ? null : () => _open(context),
  );

  void _open(BuildContext context) {
    final String route = GettingStartedStepLabel.route(step);

    switch (GettingStartedStepLabel.open(step)) {
      case QuickActionOpen.push:
        context.push(route);
      case QuickActionOpen.goTab:
        context.go(route);
    }
  }
}
