import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../domain/entities/app_error_notice.dart';
import '../../../domain/enums/app_notice_type.dart';

/// The whole app, replaced by what the owner typed into `app_config`.
///
/// **It offers nothing to tap.** There is no retry, no dismiss and no way
/// round it: the notice is on because the app is not worth using right now,
/// and a button would be an invitation to find out otherwise. It goes away
/// when the owner turns it off, which the live config does within a frame.
///
/// Every word on it comes from the document, so nothing here is localized —
/// the owner writes the sentence their sellers read, the way they write a
/// store link.
class ErrorNoticeScreen extends StatelessWidget {
  const ErrorNoticeScreen({required this.notice, super.key});

  final AppErrorNotice notice;

  @override
  Widget build(BuildContext context) => SdErrorViewV3(
    icon: notice.type.icon,
    tone: notice.type.tone,
    title: notice.title,
    message: notice.subtitle1,
    // The second line the owner wrote, not a technical detail — so it ships
    // in release, unlike the one `StartupErrorScreen` puts here.
    detail: notice.subtitle2.isEmpty ? null : notice.subtitle2,
  );
}
