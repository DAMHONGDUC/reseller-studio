import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/app_error_notice.dart';
import '../../providers.dart';
import '../screens/error_notice_screen/error_notice_screen.dart';

/// Puts [ErrorNoticeScreen] in front of the whole app while `app_config` says
/// to, and takes it away when it stops.
///
/// **It replaces its child rather than covering it**, which is the difference
/// from `ForceUpdateGate` and the reason it is a second widget. A sheet is
/// raised over a running app — the router is still built, screens still
/// listen, Firestore is still read behind the glass. This one is on because
/// the app underneath is not worth running, so nothing underneath is built.
///
/// **It outranks the forced update**, and sits above it for that reason: both
/// can be true at once, and "we are down" is the more useful of the two
/// sentences. With the child gone the update sheet has no navigator to open
/// onto, so the precedence is structural rather than a rule somebody has to
/// remember.
class ErrorNoticeGate extends ConsumerStatefulWidget {
  const ErrorNoticeGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ErrorNoticeGate> createState() => _ErrorNoticeGateState();
}

class _ErrorNoticeGateState extends ConsumerState<ErrorNoticeGate> {
  @override
  void initState() {
    super.initState();

    // `fireImmediately` because a cached config resolves before this widget
    // builds: a listener that only fired on *changes* would never log the
    // launch that opened straight onto the notice.
    ref.listenManual<AppErrorNotice?>(
      appErrorNoticeProvider,
      (AppErrorNotice? previous, AppErrorNotice? next) => _log(previous, next),
      fireImmediately: true,
    );
  }

  /// Both edges, because either one is the answer to "why did the app look
  /// like that at 11:40" — and the data is the notice's shape, never its
  /// words (hard rule 9 is about credentials, but the log is a Crashlytics
  /// payload either way and the sentence is already on screen).
  void _log(AppErrorNotice? previous, AppErrorNotice? next) {
    if ((previous == null) == (next == null)) return;

    SdLogger.action(
      LogTagConstant.appConfig,
      next == null ? 'Error notice lifted' : 'Error notice raised',
      (next ?? previous)!.toLogData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppErrorNotice? notice = ref.watch(appErrorNoticeProvider);

    if (notice == null) return widget.child;

    return ErrorNoticeScreen(notice: notice);
  }
}
