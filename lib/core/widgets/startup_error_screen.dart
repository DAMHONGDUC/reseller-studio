import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../bootstrap/app_startup_failure.dart';
import '../config/dev_flags.dart';
import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';

/// What the seller sees instead of the app when a startup step failed in a way
/// the app cannot open past.
///
/// It is the last screen in the app that can still say anything, so it assumes
/// nothing below it works: no router, no Firebase, no workspace, no provider.
/// The only things it needs are a theme and the strings, which is why it is
/// built directly under `MaterialApp` rather than reached by a route.
///
/// **The raw failure is a debug affordance and never ships** (hard rule 6).
/// [DevFlags.isDebugOrProfile] is `const`, so the release binary contains
/// `null` there and the detail row is not in it at all.
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({required this.failure, super.key});

  /// The step that failed, and what it threw.
  final AppStartupFailure failure;

  @override
  Widget build(BuildContext context) => SdErrorViewV3(
    icon: AppIconConstant.error,
    title: context.l10n.errorStartupTitle,
    message: context.l10n.errorStartupMessage,
    detail: DevFlags.isDebugOrProfile ? failure.detail : null,
  );
}
