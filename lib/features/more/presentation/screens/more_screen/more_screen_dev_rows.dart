part of 'more_screen.dart';

/// The two dev rows that end General: fill the open workspace, or empty it.
///
/// - **hidden without dev mode**, checked by General and again here: one of
///   them deletes, so one guard being forgotten must not be enough
/// - **one tap runs it** — no dialog (`lib/features/workspace/CLAUDE.md`)
/// - strings are hardcoded English: developer UI that never reaches a seller
///   (hard rule 7's exception)
final class _DevRowActions {
  /// Runs [action] and reports its count; the controller already logged a
  /// failure, so this only tells the developer.
  static Future<void> run(
    BuildContext context,
    Future<int> Function() action,
    String Function(int count) done,
  ) async {
    try {
      final int count = await action();

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(context, done(count));
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }
}

class _SeedDataRow extends ConsumerWidget {
  const _SeedDataRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(devModeEnabledProvider)) return const SizedBox.shrink();

    final bool running = ref.watch(seedDataControllerProvider);
    final bool hasWorkspace = ref.watch(hasWorkspaceProvider);

    return _MoreRowTile(
      icon: AppIconConstant.database,
      label: 'Seed demo data',
      value: hasWorkspace ? null : 'Needs a workspace',
      trailing: running ? const SdLoadingV3() : null,
      showChevron: false,
      onTap: hasWorkspace && !running
          ? () => _DevRowActions.run(
              context,
              ref.read(seedDataControllerProvider.notifier).seed,
              (int count) => 'Seeded $count documents.',
            )
          : null,
    );
  }
}

class _DeleteAllDataRow extends ConsumerWidget {
  const _DeleteAllDataRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(devModeEnabledProvider)) return const SizedBox.shrink();

    final bool running = ref.watch(deleteAllDataControllerProvider);
    final bool hasWorkspace = ref.watch(hasWorkspaceProvider);

    return _MoreRowTile(
      icon: AppIconConstant.deleteForever,
      label: 'Delete all data',
      value: hasWorkspace ? null : 'Needs a workspace',
      color: context.sdTheme3.danger,
      trailing: running ? const SdLoadingV3() : null,
      showChevron: false,
      onTap: hasWorkspace && !running
          ? () => _DevRowActions.run(
              context,
              ref.read(deleteAllDataControllerProvider.notifier).deleteAll,
              (int count) => 'Deleted $count documents.',
            )
          : null,
    );
  }
}
