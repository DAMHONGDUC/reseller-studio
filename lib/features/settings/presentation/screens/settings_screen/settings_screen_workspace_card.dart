part of 'settings_screen.dart';

/// The business itself — name, where it files, what it counts in.
///
/// **It shows the facts and opens one screen to change them** — owner's rule.
/// It used to open a picker per row and save on the tap; the switcher now
/// opens the same business detail screen, and two screens writing the same
/// document is the state where one of them quietly stops matching.
///
/// The facts are drawn for a member and a viewer too. The business's currency
/// and country explain every figure on every other screen, and hiding them
/// from a teammate would make the app look broken rather than restricted —
/// what a role changes is whether the Edit row is offered.
class _WorkspaceCard extends ConsumerWidget {
  const _WorkspaceCard({required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdCardV3(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SettingRow(
          label: context.l10n.workspaceNameLabel,
          value: workspace.name,
        ),
        _SettingRow(
          label: context.l10n.workspaceCountry,
          value: CountryLabel.of(context, workspace.country),
        ),
        _SettingRow(
          label: context.l10n.workspaceCurrency,
          value: CurrencyLabel.of(context, workspace.currency),
        ),
        _SettingRow(
          label: context.l10n.workspaceStaleAfter,
          value: context.l10n.workspaceStaleAfterDays(
            workspace.staleThresholdDays,
          ),
        ),
        _SettingRow(
          label: context.l10n.workspaceLowStock,
          value: context.l10n.workspaceLowStockItems(
            workspace.lowStockThreshold,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        if (ref.watch(canEditWorkspaceProvider))
          SdButtonV3(
            variant: SdButtonVariantV3.outlined,
            label: context.l10n.workspaceEdit,
            icon: AppIconConstant.edit,
            expand: true,
            onPressed: () =>
                context.push(AppRoutes.workspaceDetail(workspace.id)),
          )
        else
          // Drawn rather than hidden: a viewer needs to know the figures above
          // are the business's settings, not a bug.
          Text(
            context.l10n.workspaceReadOnlyNote,
            style: context.textTheme3.bodySmall!.muted3(context),
          ),
      ],
    ),
  );
}
