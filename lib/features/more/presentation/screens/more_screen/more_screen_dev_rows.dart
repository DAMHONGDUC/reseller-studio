part of 'more_screen.dart';

/// The dev rows that end General: fill the open workspace, test Crashlytics,
/// or empty the workspace.
///
/// - **hidden without dev mode**, checked by General and again here: one of
///   them deletes, so one guard being forgotten must not be enough
/// - **one tap runs it** — no dialog (`lib/features/workspace/CLAUDE.md`)
/// - strings are hardcoded English: developer UI that never reaches a seller
///   (hard rule 7's exception)
final class _DevRowActions {
  /// Runs [action] and reports its result; the controller already logged a
  /// failure, so this only tells the developer.
  static Future<void> run<T>(
    BuildContext context,
    Future<T> Function() action,
    String Function(T result) done,
  ) async {
    try {
      final T result = await action();

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(context, done(result));
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

/// Sends one non-fatal test report, so a developer can see it land.
class _CrashlyticsTestRow extends ConsumerWidget {
  const _CrashlyticsTestRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(devModeEnabledProvider)) return const SizedBox.shrink();

    final bool running = ref.watch(crashlyticsTestControllerProvider);

    return _MoreRowTile(
      icon: AppIconConstant.bugReport,
      label: 'Test Crashlytics',
      trailing: running ? const SdLoadingV3() : null,
      showChevron: false,
      onTap: running
          ? null
          : () => _DevRowActions.run(
              context,
              ref.read(crashlyticsTestControllerProvider.notifier).send,
              (bool sent) => sent
                  ? 'Test report sent. It reaches the dashboard in a few minutes.'
                  : 'No Crashlytics in this build — Firebase is not configured.',
            ),
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
