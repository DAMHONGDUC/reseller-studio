part of 'notification_settings_screen.dart';

/// Says the switches below are moot while the system has notifications off,
/// and opens the way to turn them back on.
///
/// Read again on resume, so a seller back from Settings sees it go.
class _PushBlockedCard extends ConsumerStatefulWidget {
  const _PushBlockedCard();

  @override
  ConsumerState<_PushBlockedCard> createState() => _PushBlockedCardState();
}

class _PushBlockedCardState extends ConsumerState<_PushBlockedCard> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(pushBlockedProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool blocked = ref.watch(pushBlockedProvider).value ?? false;

    if (!blocked) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        left: SdContentPaddingV3.horizontal,
        right: SdContentPaddingV3.horizontal,
        bottom: SdSpacingConstant.h16,
      ),
      child: AppStatusCard(
        icon: AppIconConstant.notificationsOff,
        tint: context.sdTheme3.warning,
        title: context.l10n.permissionNotificationsTitle,
        detail: context.l10n.notificationSettingsBlockedDetail,
        onTap: () => PermissionSettingsSheet.show(
          context,
          permission: AppPermission.notifications,
        ),
      ),
    );
  }
}
