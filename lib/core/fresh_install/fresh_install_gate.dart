import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../widgets/splash_screen.dart';
import 'app_fresh_install.dart';

/// Holds the app on the splash screen until it is known that the data on this
/// device belongs to the environment this binary talks to.
///
/// **Nothing below it is built until the check finishes, and that is the whole
/// job.** The wipe signs the seller out and calls Firestore's
/// `clearPersistence`, which throws `failed-precondition` once that client is
/// running — so this has to sit above every widget that opens a stream, which
/// on the first frame means above `ForceUpdateGate` and its `app_config` read.
/// Letting the first screen build alongside the wipe would also race the
/// sign-out against the screens reading that session.
///
/// **It renders the app's own [SplashScreen], not a blank frame.** The check
/// used to run in `AppBootstrap` before `runApp`, where the only thing on
/// screen is the platform launch image and a wipe that takes a second looks
/// like a hang. Here the app is already up, themed, and showing the same
/// screen a returning seller sees while auth resolves — so a wipe is
/// indistinguishable from a normal cold start, which is what it should be.
class FreshInstallGate extends ConsumerWidget {
  const FreshInstallGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SdFreshInstallOutcome> check = ref.watch(
      freshInstallProvider,
    );

    // Errors resolve to the app, never to an error screen: `SdFreshInstall`
    // catches its own and a device that could not be checked is the one the
    // seller is holding.
    return check.isLoading ? const SplashScreen() : child;
  }
}
