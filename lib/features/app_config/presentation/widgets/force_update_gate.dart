import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../providers.dart';
import 'force_update_block.dart';

/// Draws [ForceUpdateBlock] over the whole app whenever the running build is
/// too old, and takes it away if the config says otherwise.
///
/// **It wraps the whole app rather than living on a screen.** The block is
/// about the binary, not about a route, so every screen — signed out, mid-form,
/// deep-linked — is covered by one widget instead of each remembering to ask.
///
/// **It draws the block as its own child, never as a route.** A modal sheet is
/// a pageless route hanging off the page below it, and a go_router redirect
/// replaces that page — which is how the block that opened over the splash
/// disappeared on the way to Home and never came back. A widget the gate owns
/// is one no navigation can remove, and it also means the block goes up and
/// comes down from the provider alone: no post-frame callback, no `_showing`
/// flag, and no `pop()` that could take somebody else's route with it.
class ForceUpdateGate extends ConsumerStatefulWidget {
  const ForceUpdateGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends ConsumerState<ForceUpdateGate> {
  @override
  void initState() {
    super.initState();

    // `fireImmediately` because the answer can already be yes on the first
    // frame — a cached config resolves before this widget is built, and a
    // listener that only fires on *changes* would never log the launch that
    // opened straight onto the block.
    ref.listenManual<bool>(
      forceUpdateRequiredProvider,
      _log,
      fireImmediately: true,
    );
  }

  /// Both edges, because either one is the answer to "why could nobody use
  /// the app at 11:40". A launch that is not blocked is not an edge, so the
  /// first read is compared against `false` rather than against null.
  void _log(bool? previous, bool next) {
    if ((previous ?? false) == next) return;

    SdLogger.action(
      LogTagConstant.appConfig,
      next ? 'Force update block raised' : 'Force update lifted',
      ref.read(currentUpdatePolicyProvider).toLogData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool required = ref.watch(forceUpdateRequiredProvider);

    // `expand`, so the router's navigator below is given the tight
    // constraints it would have had without the stack.
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (required) const ForceUpdateBlock(),
      ],
    );
  }
}
