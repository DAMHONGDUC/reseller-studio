part of 'activity_screen.dart';

/// One line of the log: what happened, to what kind of record, and when.
///
/// **The words come from the pair, not from string concatenation.** Building
/// "Item" + " " + "added" reads fine in English and falls apart in every
/// language that inflects — so each combination is its own ARB key, and an
/// unrecognised pair falls back to one neutral line rather than to half a
/// sentence.
class _ActivityRow extends ConsumerWidget {
  const _ActivityRow({required this.entry});

  final ActivityEntry entry;

  static String _title(BuildContext context, ActivityEntry entry) =>
      switch ((entry.entityType, entry.action)) {
        (ActivityEntityType.item, ActivityAction.created) =>
          context.l10n.activityItemCreated,
        (ActivityEntityType.item, ActivityAction.updated) =>
          context.l10n.activityItemUpdated,
        (ActivityEntityType.item, ActivityAction.deleted) =>
          context.l10n.activityItemDeleted,
        (ActivityEntityType.order, ActivityAction.created) =>
          context.l10n.activityOrderCreated,
        (ActivityEntityType.order, ActivityAction.updated) =>
          context.l10n.activityOrderUpdated,
        (ActivityEntityType.order, ActivityAction.deleted) =>
          context.l10n.activityOrderDeleted,
        (ActivityEntityType.listing, ActivityAction.created) =>
          context.l10n.activityListingCreated,
        (ActivityEntityType.listing, ActivityAction.updated) =>
          context.l10n.activityListingUpdated,
        (ActivityEntityType.listing, ActivityAction.deleted) =>
          context.l10n.activityListingDeleted,
        // A build older than the entry that wrote it. One honest line beats
        // guessing which of the known pairs it meant.
        _ => context.l10n.activityRecordChanged,
      };

  static IconData _icon(ActivityEntityType type) => switch (type) {
    ActivityEntityType.item => AppIconConstant.inventory,
    ActivityEntityType.order => AppIconConstant.receiptLong,
    ActivityEntityType.listing => AppIconConstant.sell,
    ActivityEntityType.unknown => AppIconConstant.history,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? uid = ref.watch(currentUidProvider);
    // Only ever "you", "a teammate" or "automatic". The log stores a uid and
    // the rules deliberately forbid reading anyone else's user document, so
    // naming another person here is not something the client can do.
    final String who = switch (entry.actorId) {
      null => context.l10n.activityBySystem,
      final String actor when actor == uid => context.l10n.settingsSignedIn,
      _ => context.l10n.activityByTeammate,
    };

    return Padding(
      padding: SdContentPaddingV3.row,
      child: Row(
        children: <Widget>[
          SdIconTileV3(
            icon: _icon(entry.entityType),
            tint: context.colorScheme3.primary,
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _title(context, entry),
                  style: context.textTheme3.bodyMedium!.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
                Text(who, style: context.textTheme3.bodySmall!.muted3(context)),
              ],
            ),
          ),
          Text(
            DateTimeUtils.mediumDate(
              entry.createdAt,
              locale: context.localeTag,
            ),
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
        ],
      ),
    );
  }
}
