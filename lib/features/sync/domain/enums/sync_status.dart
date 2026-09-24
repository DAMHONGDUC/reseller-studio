import 'package:flutter/widgets.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_tag_hue.dart';

/// Whether what this device holds has reached the server.
enum SyncStatus {
  /// Nothing has answered yet — the first frame, before the check returns.
  checking,

  /// A write is still waiting for the server: offline, or on its way.
  syncing,

  /// Every write the server has been sent, it has confirmed.
  synced,

  /// A guest: the records live in the local store and go nowhere.
  deviceOnly;

  /// Only a guest's card leads anywhere: signing in is what backs them up.
  bool get offersSignIn => this == SyncStatus.deviceOnly;
}

extension SyncStatusDisplay on SyncStatus {
  String label(BuildContext context) => switch (this) {
    SyncStatus.checking => context.l10n.syncCheckingTitle,
    SyncStatus.syncing => context.l10n.syncSyncingTitle,
    SyncStatus.synced => context.l10n.syncSyncedTitle,
    SyncStatus.deviceOnly => context.l10n.syncDeviceOnlyTitle,
  };

  String detail(BuildContext context) => switch (this) {
    SyncStatus.checking => context.l10n.syncCheckingSubtitle,
    SyncStatus.syncing => context.l10n.syncSyncingSubtitle,
    SyncStatus.synced => context.l10n.syncSyncedSubtitle,
    SyncStatus.deviceOnly => context.l10n.syncDeviceOnlySubtitle,
  };

  /// Amber for records at risk, blue for in flight, green for safe.
  Color color(BuildContext context) => switch (this) {
    SyncStatus.checking => AppTagHue.grey,
    SyncStatus.syncing => AppTagHue.blue,
    SyncStatus.synced => AppTagHue.green,
    SyncStatus.deviceOnly => AppTagHue.amber,
  }.of(context);

  IconData get icon => switch (this) {
    SyncStatus.checking => AppIconConstant.cloudSync,
    SyncStatus.syncing => AppIconConstant.cloudSync,
    SyncStatus.synced => AppIconConstant.cloudDone,
    SyncStatus.deviceOnly => AppIconConstant.cloudOff,
  };
}
