part of 'home_screen.dart';

/// Every create action in the app, plus the page explaining how they connect.
///
/// **The create actions are scattered by design** — each lives on the screen
/// that owns the records it makes, behind that screen's own `SdFabV3`
/// (owner's rule). That is right for a seller already on the screen and wrong
/// for one who opened the app holding a receipt: recording an expense from
/// Home is three taps otherwise.
///
/// This does not replace those buttons and must not: it is a shortcut into
/// them, so every row pushes the screen that owns the action rather than
/// opening a form Home would then have to know how to save.
///
/// **About rides last, and Analytics just above it** — owner's rule. They are
/// the two rows here that do not create something; About sits two levels deep
/// under Settings, so this is what keeps it findable, and the actions above
/// them keep the section's shape.
///
/// **How a row opens is a property of the row** (`QuickActionOpen`), not
/// something worked out here: Analytics is a branch root, so it opens with
/// `go` rather than being pushed over Home.
///
/// **Rows, and near the bottom** — owner's rule. Home answers "what needs
/// attention today" first; a launcher above the figures made the screen open
/// on the wrong thing. The shortcut card at the top is what keeps it one tap
/// away for a seller who came to add something.
class _QuickAction extends StatelessWidget {
  const _QuickAction();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
    child: AppListCard(
      children: <Widget>[
        for (final QuickActionSection section in QuickActionConstant.sections)
          _QuickActionSection(section: section),
      ],
    ),
  );
}

class _QuickActionSection extends StatelessWidget {
  const _QuickActionSection({required this.section});

  final QuickActionSection section;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Semantics(
        header: true,
        child: Padding(
          padding: SdContentPaddingV3.row,
          child: Text(
            QuickActionSectionLabel.of(context, section.kind),
            style: context.textTheme3.titleSmall!.semiBold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
        ),
      ),
      for (int index = 0; index < section.actions.length; index++) ...<Widget>[
        if (index > 0) const SdDividerV3(),
        _QuickActionRow(action: section.actions[index]),
      ],
    ],
  );
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) => AppListRow(
    title: QuickActionLabel.of(context, action.kind),
    icon: action.icon,
    onTap: () => switch (action.open) {
      QuickActionOpen.push => context.push(action.route),
      QuickActionOpen.goTab => context.go(action.route),
    },
  );
}
