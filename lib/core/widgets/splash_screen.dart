import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../fresh_install/app_fresh_install.dart';
import '../router/splash_hold.dart';

/// What the app shows while it is not ready yet — and, while it is showing,
/// the thing that makes it ready.
///
/// Deliberately almost empty. This screen is visible for a few hundred
/// milliseconds on a warm start and it must not look like a screen that
/// failed to load — no message, no spinner text, nothing that a user could
/// read and then be confused when it vanishes.
///
/// It is also the only route a signed-out user can reach without being
/// redirected to login, which is why it lives in `core/widgets` rather than
/// under `features/auth`: it belongs to the router, not to authentication.
///
/// **It owns the fresh-install wipe, and that is the whole reason it takes a
/// [child].** Owner's rule. The device may be carrying another environment's
/// session and cached documents (`docs/rules/ENV.md`), and the seller should
/// see one screen while that is dealt with — not a frozen launch image, and
/// not a second loading widget that looks slightly different. So the wipe runs
/// behind this screen and this screen is what waits for it.
///
/// **Nothing below it is built until the check finishes.** The wipe signs the
/// seller out and calls Firestore's `clearPersistence`, which throws
/// `failed-precondition` once that client is running — so this has to sit
/// above every widget that opens a stream, which on the first frame means
/// above `ForceUpdateGate` and its `app_config` read. Letting the first screen
/// build alongside would also race the sign-out against the screens reading
/// that session.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({this.child, super.key});

  /// What to show once the device is known to belong to this build.
  ///
  /// Null on the router's own `/splash` route, which is already *inside* the
  /// tree this screen gates: there the check has long finished and the screen
  /// is doing its other job, covering an auth state that has not resolved.
  final Widget? child;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// How long the loading animation has left to run.
  ///
  /// **The route's copy of this screen owns it, and the wrapper's does not.**
  /// This class does two jobs — it is the `/splash` route, and it is the gate
  /// above the whole app that runs the fresh-install wipe — and only the first
  /// is a screen the router can be held on. Started here rather than in
  /// [SplashHoldController] so nothing is counting down while the animation is
  /// not on screen.
  Timer? _hold;

  @override
  void initState() {
    super.initState();

    if (widget.child == null) {
      _hold = Timer(
        SplashHoldController.minimum,
        () => ref.read(splashHoldProvider.notifier).release(),
      );
    }
  }

  @override
  void dispose() {
    _hold?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? ready = widget.child;
    final AsyncValue<SdFreshInstallOutcome> check = ref.watch(
      freshInstallProvider,
    );

    // Errors resolve to the app, never to an error screen: `SdFreshInstall`
    // catches its own, and a device that could not be checked is the one the
    // seller is holding.
    if (ready == null || check.isLoading) {
      return const SdScaffoldV3(body: SdLoadingV3Page());
    }

    return ready;
  }
}
