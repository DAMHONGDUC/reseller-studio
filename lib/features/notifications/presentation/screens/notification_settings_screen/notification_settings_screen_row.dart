part of 'notification_settings_screen.dart';

/// One reminder, and what turning it off costs.
///
/// The consequence is written next to the switch rather than left implied: a
/// row that says only "Payout not arrived" gives a seller no way to know they
/// are switching off the one reminder that hands them money back.
class _PreferenceRow extends ConsumerWidget {
  const _PreferenceRow({required this.type, required this.isEnabled});

  final NotificationType type;
  final bool isEnabled;

  Future<void> _set(BuildContext context, WidgetRef ref, bool enabled) async {
    try {
      await ref
          .read(notificationPreferencesControllerProvider.notifier)
          .setEnabled(type, enabled: enabled);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isBusy = ref.watch(notificationPreferencesControllerProvider);

    return AppListRow(
      title: type.label(context),
      subtitle: type.description(context),
      icon: type.icon,
      // The switch is the interaction, so the chevron would be an affordance
      // leading nowhere.
      showChevron: false,
      iconTint: isEnabled
          ? context.colorScheme3.primary
          : context.sdTheme3.textTertiary,
      trailing: Switch(
        value: isEnabled,
        onChanged: isBusy
            ? null
            : (bool enabled) => _set(context, ref, enabled),
      ),
    );
  }
}
