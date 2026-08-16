part of 'home_screen.dart';

/// Every create action in the app, one tap from where a seller starts.
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
        for (final QuickAction action in QuickActionConstant.actions)
          AppListRow(
            title: QuickActionLabel.of(context, action.kind),
            icon: action.icon,
            onTap: () => context.push(action.route),
          ),
      ],
    ),
  );
}

/// What is worth *reading* rather than doing.
///
/// **Its own section, under the actions** — owner's rule. About is not a
/// create action, and putting it among them would make a seller scanning for
/// "add" step over a row that adds nothing. Separating the two is also what
/// keeps `QuickActionConstant` able to say "only create actions" and mean it.
class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
    child: AppListCard(
      children: <Widget>[
        AppListRow(
          title: context.l10n.moreAbout,
          subtitle: context.l10n.aboutTagline,
          icon: Symbols.info_rounded,
          onTap: () => context.push(AppRoutes.about),
        ),
      ],
    ),
  );
}
