part of 'more_screen.dart';

/// Heads More with whether this device's records have reached the server.
///
/// A guest's card leads to sign-in, the one thing that backs them up; an
/// account's card only reports. Same shape as `_HomeGuestBanner`
/// (`AppStatusCard`), with its detail line capped at one — the sync copy is
/// written to fit on it.
class _SyncStatusCard extends ConsumerWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SyncStatus status =
        ref.watch(syncStatusProvider).value ?? SyncStatus.checking;

    return AppStatusCard(
      icon: status.icon,
      tint: status.color(context),
      title: status.label(context),
      detail: status.detail(context),
      detailMaxLines: 1,
      semanticLabel: status.label(context),
      onTap: status.offersSignIn ? () => context.push(AppRoutes.login) : null,
    );
  }
}
