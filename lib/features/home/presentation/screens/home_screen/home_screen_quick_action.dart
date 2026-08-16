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
/// **About rides last** — owner's rule. It is the one row here that does not
/// create something, and it sits two levels deep under Settings, so this is
/// what keeps it findable. Last in the list, so the actions above it keep the
/// section's shape.
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
