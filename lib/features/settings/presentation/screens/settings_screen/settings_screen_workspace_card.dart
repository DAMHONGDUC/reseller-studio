part of 'settings_screen.dart';

/// The business itself — name, where it files, what it counts in.
///
/// **These were read-only until now, and the country being read-only was a
/// trap**: it decides the tax jurisdiction, the tax year boundary and the
/// mileage rate, so picking the wrong one at setup was permanent.
///
/// One tap per field, saved immediately. A form with a Save button would make
/// correcting one picker a three-step ceremony, and there is nothing here that
/// only makes sense changed together.
class _WorkspaceCard extends ConsumerWidget {
  const _WorkspaceCard({required this.workspace});

  final Workspace workspace;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final String? name = await NameEntrySheet.show(
      context,
      title: context.l10n.workspaceRenameTitle,
      label: context.l10n.workspaceNameLabel,
      initialValue: workspace.name,
    );

    if (name == null || !context.mounted) return;

    await _save(context, ref, () => _edit(ref).rename(name));
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) async {
    final String? code = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.workspaceCurrency,
      selected: workspace.currency,
      options: WorkspaceConstant.currencies
          .map(
            (String code) => PickerOption<String>(
              value: code,
              label: WorkspaceOptionLabel.currency(context, code),
              caption: code,
            ),
          )
          .toList(),
    );

    if (code == null || !context.mounted) return;

    await _save(context, ref, () => _edit(ref).setCurrency(code));
  }

  Future<void> _pickCountry(BuildContext context, WidgetRef ref) async {
    final String? code = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.workspaceCountry,
      selected: workspace.country,
      options: WorkspaceConstant.countries
          .map(
            (String code) => PickerOption<String>(
              value: code,
              label: WorkspaceOptionLabel.country(context, code),
            ),
          )
          .toList(),
    );

    if (code == null || !context.mounted) return;

    await _save(context, ref, () => _edit(ref).setCountry(code));
  }

  Future<void> _pickStaleThreshold(BuildContext context, WidgetRef ref) async {
    final int? days = await OptionPickerSheet.show<int>(
      context,
      title: context.l10n.workspaceStaleAfter,
      selected: workspace.staleThresholdDays,
      options: WorkspaceConstant.staleThresholdChoices
          .map(
            (int days) => PickerOption<int>(
              value: days,
              label: context.l10n.workspaceStaleAfterDays(days),
            ),
          )
          .toList(),
    );

    if (days == null || !context.mounted) return;

    await _save(context, ref, () => _edit(ref).setStaleThresholdDays(days));
  }

  /// **Asks once, in a dialog that says exactly what goes.** There is no undo
  /// and no export first — the same shape as deleting the account, which is
  /// the only other control in the app that destroys records.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.workspaceDeleteConfirmTitle,
        message: context.l10n.workspaceDeleteConfirmBody(workspace.name),
        icon: Symbols.warning_rounded,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.workspaceDeleteConfirm,
            isDestructive: true,
            onPressed: () => _delete(context, ref),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  /// No success message: the router replaces the screen the moment the profile
  /// stream drops the id, so a snackbar would be posted onto a route that is
  /// already gone.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      await _edit(ref).delete();
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  WorkspaceEditController _edit(WidgetRef ref) =>
      ref.read(workspaceEditControllerProvider.notifier);

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() write,
  ) async {
    try {
      await write();

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(context, context.l10n.workspaceSaved);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canEdit = ref.watch(canEditWorkspaceProvider);
    final bool canDelete = ref.watch(canDeleteWorkspaceProvider);

    if (!canEdit) return _WorkspaceReadOnlyCard(workspace: workspace);

    return AppListCard(
      children: <Widget>[
        AppListRow(
          title: context.l10n.workspaceNameLabel,
          subtitle: workspace.name,
          icon: Symbols.storefront_rounded,
          onTap: () => _rename(context, ref),
        ),
        AppListRow(
          title: context.l10n.workspaceCountry,
          subtitle: WorkspaceOptionLabel.country(context, workspace.country),
          icon: Symbols.public_rounded,
          onTap: () => _pickCountry(context, ref),
        ),
        AppListRow(
          title: context.l10n.workspaceCurrency,
          subtitle: WorkspaceOptionLabel.currency(context, workspace.currency),
          icon: Symbols.payments_rounded,
          onTap: () => _pickCurrency(context, ref),
        ),
        AppListRow(
          title: context.l10n.workspaceStaleAfter,
          subtitle: context.l10n.workspaceStaleAfterDays(
            workspace.staleThresholdDays,
          ),
          icon: Symbols.hourglass_bottom_rounded,
          onTap: () => _pickStaleThreshold(context, ref),
        ),
        // Owner only. An admin runs the business; ending it belongs to
        // whoever owns it, and the Cloud Function refuses anyone else.
        if (canDelete)
          AppListRow(
            title: context.l10n.workspaceDelete,
            subtitle: context.l10n.workspaceDeletePermanent,
            icon: Symbols.delete_forever_rounded,
            iconTint: context.sdTheme3.danger,
            showChevron: false,
            onTap: () => _confirmDelete(context, ref),
          ),
      ],
    );
  }
}

/// What a member or a viewer sees: the same facts, none of the affordances.
///
/// Drawn rather than hidden — the business's currency and country explain
/// every figure on every other screen, and hiding them from a teammate would
/// make the app look broken to them rather than restricted.
class _WorkspaceReadOnlyCard extends StatelessWidget {
  const _WorkspaceReadOnlyCard({required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context) => SdCardV3(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SettingRow(
          label: context.l10n.workspaceNameLabel,
          value: workspace.name,
        ),
        _SettingRow(
          label: context.l10n.workspaceCountry,
          value: WorkspaceOptionLabel.country(context, workspace.country),
        ),
        _SettingRow(
          label: context.l10n.workspaceCurrency,
          value: WorkspaceOptionLabel.currency(context, workspace.currency),
        ),
        _SettingRow(
          label: context.l10n.workspaceStaleAfter,
          value: context.l10n.workspaceStaleAfterDays(
            workspace.staleThresholdDays,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        Text(
          context.l10n.workspaceReadOnlyNote,
          style: context.textTheme3.bodySmall!.muted3(context),
        ),
      ],
    ),
  );
}
