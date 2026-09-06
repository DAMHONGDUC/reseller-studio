import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/router/app_navigator_key.dart';
import '../../providers.dart';
import 'force_update_sheet.dart';

/// Raises [ForceUpdateSheet] whenever the running build is too old, and takes
/// it away if the config says otherwise.
///
/// **It wraps the whole app rather than living on a screen.** The block is
/// about the binary, not about a route, so every screen — signed out, mid-form,
/// deep-linked — is covered by one widget instead of each remembering to ask.
///
/// **It shows the sheet on the root navigator's own context**, taken from
/// [AppNavigatorKey.root]: this widget sits above go_router's navigator, so
/// its own context has none to push a route onto.
class ForceUpdateGate extends ConsumerStatefulWidget {
  const ForceUpdateGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends ConsumerState<ForceUpdateGate> {
  bool _showing = false;

  @override
  void initState() {
    super.initState();

    // `fireImmediately` because the answer can already be yes on the first
    // frame — a cached config resolves before this widget is built, and a
    // listener that only fires on *changes* would never open the sheet.
    ref.listenManual<bool>(
      forceUpdateRequiredProvider,
      (bool? previous, bool next) => _sync(next),
      fireImmediately: true,
    );
  }

  /// Deferred to the end of the frame: the navigator does not exist yet during
  /// the first build, and pushing a route while one is in flight throws.
  void _sync(bool required) {
    if (required == _showing) return;

    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;

      required ? _open() : _close();
    });
  }

  Future<void> _open() async {
    final BuildContext? context = AppNavigatorKey.root.currentContext;

    if (_showing || context == null) return;

    _showing = true;

    SdLogger.action(
      LogTagConstant.appConfig,
      'Force update sheet raised',
      ref.read(currentUpdatePolicyProvider).toLogData(),
    );

    await ForceUpdateSheet.show(context);

    _showing = false;
  }

  /// The seller is released when the config stops asking — a build number
  /// typed one digit too high is corrected in the console, not in a release.
  void _close() {
    if (!_showing) return;

    SdLogger.action(
      LogTagConstant.appConfig,
      'Force update lifted',
      ref.read(currentUpdatePolicyProvider).toLogData(),
    );

    AppNavigatorKey.root.currentState?.pop();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
