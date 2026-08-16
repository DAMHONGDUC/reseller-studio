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
/// **Rows, and last on the screen** — owner's rule. Home answers "what needs
/// attention today" first; a grid of eight tiles above the figures made the
/// screen open on a launcher instead of on the answer. At the bottom it is
/// where a seller who came to *add* something scrolls to, and it costs the
/// seller who came to *read* nothing.
class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
    child: AppListCard(
      children: <Widget>[
        for (final QuickAddAction action in QuickAddConstant.actions)
          AppListRow(
            title: QuickAddLabel.of(context, action.kind),
            icon: action.icon,
            onTap: () => context.push(action.route),
          ),
      ],
    ),
  );
}
