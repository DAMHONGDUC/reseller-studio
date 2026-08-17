import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../auth/providers.dart';
import '../../../domain/entities/activity_entry.dart';
import '../../../providers.dart';

part 'activity_screen_row.dart';

/// The audit log (plan §23) — who changed what, most recent first.
///
/// **Read-only, and there is no way to make it otherwise.** Entries come from
/// Cloud Functions triggers, which is what stops `actorId` being forged
/// (hard rule 12); the repository has no `save` and the screen has no create
/// action.
///
/// **It is empty until the functions are deployed**, in every environment
/// including mock mode. The empty state is written for the ordinary reason a
/// workspace has no history — it is new — rather than for the missing backend,
/// because a seller should never be shown the app's deployment state.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ActivityEntry> entries =
        ref.watch(recentActivityProvider).value ?? const <ActivityEntry>[];

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.activityTitle),
      body: entries.isEmpty
          ? SdEmptyStateV3(
              icon: Symbols.history_rounded,
              title: context.l10n.activityEmptyTitle,
              message: context.l10n.activityEmptyMessage,
            )
          : ListView.separated(
              padding: SdContentPaddingV3.fullBleed(context),
              itemCount: entries.length,
              separatorBuilder: (BuildContext context, int _) =>
                  const SdDividerV3(),
              itemBuilder: (BuildContext context, int index) =>
                  _ActivityRow(entry: entries[index]),
            ),
    );
  }
}
