import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';

/// The two ways a list can be empty, told apart.
///
/// **"Nothing matches this filter" and "you have not started yet" are
/// different sentences**, and saying the first to a seller who has never added
/// anything is a claim about their business that is not true — the same
/// mistake hard rule 5 exists to stop one level down, where an unknown figure
/// renders `—` rather than `0`. It also strands them: there is no filter to
/// clear, so the screen names an action that does not exist.
///
/// The filter half is written once here because it is the same everywhere: a
/// filter is on, turn it off. The other half stays the screen's own, because
/// what to do next differs on every list — and it is the half that carries
/// [emptyAction], since a first empty screen with no way out of it is where a
/// new seller stops.
class AppListEmptyState extends StatelessWidget {
  const AppListEmptyState({
    required this.hasAny,
    required this.noMatchMessage,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.emptyAction,
    super.key,
  });

  /// Whether the list holds anything at all, before the filter runs. It is the
  /// unfiltered source that answers this — a count taken after filtering is
  /// the bug this widget exists to fix.
  final bool hasAny;

  final String noMatchMessage;

  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  /// The way on. Pass an `SdButtonV3`; null only where the list genuinely has
  /// nothing to offer yet.
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) => hasAny
      ? SdEmptyStateV3(
          icon: AppIconConstant.filterAltOff,
          title: context.l10n.commonNothingHere,
          message: noMatchMessage,
        )
      : SdEmptyStateV3(
          icon: emptyIcon,
          title: emptyTitle,
          message: emptyMessage,
          action: emptyAction,
        );
}
