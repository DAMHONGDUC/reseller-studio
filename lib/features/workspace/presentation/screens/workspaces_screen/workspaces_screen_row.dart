part of 'workspaces_screen.dart';

/// One business. The badge marks the current one as well as the tint would —
/// colour is never the only signal.
class _WorkspaceRow extends StatelessWidget {
  const _WorkspaceRow({
    required this.workspace,
    required this.isCurrent,
    required this.onTap,
  });

  final Workspace workspace;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppListRow(
    title: workspace.name,
    subtitle: workspace.currency,
    icon: AppIconConstant.storefront,
    // Tapping the one already open is a no-op the controller short-circuits;
    // leaving it tappable keeps every row the same height and hit target.
    onTap: onTap,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (isCurrent) ...<Widget>[
          SdBadgeV3(label: context.l10n.workspacesCurrent),
          SizedBox(width: SdSpacingConstant.w8),
        ],
        // Its own tap target beside the row's, so choosing a business and
        // correcting one are never the same gesture.
        AppRowIconButton(
          icon: AppIconConstant.edit,
          tooltip: context.l10n.workspaceEdit,
          onPressed: () =>
              context.push(AppRoutes.workspaceDetail(workspace.id)),
        ),
      ],
    ),
  );
}
