part of 'more_screen.dart';

/// Heads More with whether this device's records have reached the server.
///
/// A guest's card leads to sign-in, the one thing that backs them up; an
/// account's card only reports.
class _SyncStatusCard extends ConsumerWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SyncStatus status =
        ref.watch(syncStatusProvider).value ?? SyncStatus.checking;
    final Color tint = status.color(context);

    return SdCardV3(
      padding: SdContentPaddingV3.row,
      onTap: status.offersSignIn ? () => context.push(AppRoutes.login) : null,
      semanticLabel: status.label(context),
      child: Row(
        children: <Widget>[
          SdIconTileV3(icon: status.icon, tint: tint),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  status.label(context),
                  style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
                SizedBox(height: SdSpacingConstant.h4),
                Text(
                  status.detail(context),
                  style: context.textTheme3.bodySmall!.copyWith(
                    color: context.sdTheme3.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (status.offersSignIn) ...<Widget>[
            SizedBox(width: SdSpacingConstant.w8),
            const AppRowChevron(),
          ],
        ],
      ),
    );
  }
}
