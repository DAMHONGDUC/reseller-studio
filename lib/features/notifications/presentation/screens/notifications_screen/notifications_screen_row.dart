part of 'notifications_screen.dart';

/// One line: what happened, to which business, and when.
///
/// **The words are rendered here, not read from the document.** The stored
/// title and body are the English text the push carried — a Cloud Function
/// cannot know the reader's locale — so the row builds its own from the type
/// and the count, which is what lets the translation pass fix the inbox
/// without rewriting history (hard rule 7).
class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification});

  final AppNotification notification;

  static String _title(BuildContext context, AppNotification notification) =>
      switch (notification.type) {
        NotificationType.orderCreated => context.l10n.notificationOrderCreated,
        NotificationType.offerReceived => context.l10n.notificationOfferReceived,
        NotificationType.shipmentsDue => context.l10n.notificationShipmentsDue(
          notification.count ?? 0,
        ),
        NotificationType.staleInventory => context.l10n
            .notificationStaleInventory(notification.count ?? 0),
        NotificationType.lowInventory => context.l10n.notificationLowInventory(
          notification.count ?? 0,
        ),
        NotificationType.memberJoined => context.l10n.notificationMemberJoined,
        // A build older than the notification that reached it. One honest
        // line beats guessing which of the known types it meant.
        NotificationType.unknown => context.l10n.notificationSomethingHappened,
      };

  static IconData _icon(NotificationType type) => switch (type) {
    NotificationType.orderCreated => Symbols.receipt_long_rounded,
    NotificationType.offerReceived => Symbols.local_offer_rounded,
    NotificationType.shipmentsDue => Symbols.local_shipping_rounded,
    NotificationType.staleInventory => Symbols.hourglass_bottom_rounded,
    NotificationType.lowInventory => Symbols.inventory_2_rounded,
    NotificationType.memberJoined => Symbols.group_add_rounded,
    NotificationType.unknown => Symbols.notifications_rounded,
  };

  /// Tapping reads it and goes where it points.
  ///
  /// **The business is switched first when the notification is about another
  /// one.** A seller in three businesses tapping "2 orders to ship" would
  /// otherwise land on a shipping queue belonging to whichever one happens to
  /// be open, which is the same figure meaning something else.
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final String route = notification.route;

    unawaited(
      ref.read(notificationControllerProvider.notifier).markRead(notification),
    );

    if (notification.workspaceId.isNotEmpty &&
        notification.workspaceId != ref.read(currentWorkspaceIdProvider)) {
      await ref
          .read(workspaceSwitchControllerProvider.notifier)
          .switchTo(notification.workspaceId);
    }

    if (route.isEmpty || !context.mounted) return;

    // Not awaited: the future completes when the pushed route pops, which is
    // not something this row has anything to do afterwards.
    unawaited(context.push(route));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool unread = notification.isUnread;

    return InkWell(
      onTap: () => _open(context, ref),
      child: Padding(
        padding: SdContentPaddingV3.row,
        child: Row(
          children: <Widget>[
            SdIconTileV3(
              icon: _icon(notification.type),
              // Unread is the loud state, and it is marked twice — the tile
              // takes the accent and the title takes the weight. Colour alone
              // is never the only signal.
              tint: unread
                  ? context.colorScheme3.primary
                  : context.sdTheme3.textSecondary,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Text(
                _title(context, notification),
                style: context.textTheme3.bodyMedium!.copyWith(
                  color: context.sdTheme3.textPrimary,
                  fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            Text(
              DateTimeUtils.mediumDate(
                notification.createdAt,
                locale: context.localeTag,
              ),
              style: context.textTheme3.bodySmall!.faint3(context),
            ),
          ],
        ),
      ),
    );
  }
}
