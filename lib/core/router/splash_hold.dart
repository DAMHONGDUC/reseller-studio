import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/providers.dart';
import '../../features/onboarding/providers.dart';
import '../../features/workspace/providers.dart';

/// Whether the app still has a question outstanding about where it belongs.
///
/// **It mirrors the redirect's own splash conditions and exists to be watched
/// rather than read.** `app_router.dart` answers *where to send the seller*
/// and does it inside a build, so it cannot start a timer; this answers the
/// smaller question *are we still deciding*, which is what
/// [splashHoldProvider] listens for. Change one and change the other: they are
/// the same three clauses.
final Provider<bool> appIsResolvingProvider = Provider<bool>((Ref ref) {
  final bool? signedIn = ref.watch(isSignedInProvider);
  final OnboardingStatus onboarding = ref.watch(onboardingStatusProvider);

  if (signedIn == null || onboarding == OnboardingStatus.loading) return true;

  return signedIn &&
      ref.watch(workspaceStatusProvider) == WorkspaceStatus.loading;
});

/// Keeps the loading screen up long enough to be watched.
///
/// **Owner's rule: the loading animation always plays.** Without it the splash
/// lasts whatever the network happened to cost — 80 milliseconds on a warm
/// start, which a seller reads as a glitch rather than as the app working. The
/// router asks this before it leaves the splash, so an answer that lands early
/// waits rather than flashing past.
///
/// It is a hold, never a delay: the work runs the whole time and nothing is
/// scheduled behind it. What waits is only the route change.
///
/// **It only ever keeps the seller on the splash; it never sends them
/// there.** So it is inert everywhere else, and a hold left standing while the
/// app is on Home costs nothing.
///
/// **The clock is `SplashScreen`'s, not this class's**, and that is the split
/// that makes the two halves honest: what is being waited for is the animation
/// being *seen*, which only the widget that draws it knows about. It starts
/// [minimum] when it appears and cancels it when it goes, so nothing is
/// counting down while the screen is not up.
final NotifierProvider<SplashHoldController, bool> splashHoldProvider =
    NotifierProvider<SplashHoldController, bool>(SplashHoldController.new);

/// True while the loading screen must stay on screen.
class SplashHoldController extends Notifier<bool> {
  /// How long the animation is given once it is on screen.
  ///
  /// The class *is* the policy, so the number lives with it. Long enough for
  /// the cradle to swing through a full cycle, short enough that a seller
  /// opening the app to check one order does not feel they waited.
  ///
  /// **One second, down from two** (owner's call): the app now has something
  /// to show a signed-out seller, so the splash is covering a cold start
  /// rather than an auth check, and two seconds of it read as a delay the
  /// app had chosen.
  static const Duration minimum = Duration(seconds: 1);

  /// Held from the first read, which is the router being built — the app opens
  /// on the splash, so the launch's own hold needs no trigger.
  @override
  bool build() {
    // **Re-armed when the app starts deciding again**, which is what covers
    // the moment after sign-in. Listened to rather than read: it fires outside
    // a build, so the hold is already up by the time the redirect sends the
    // seller to the screen it holds.
    ref.listen<bool>(appIsResolvingProvider, (bool? previous, bool next) {
      if (next) hold();
    });

    return true;
  }

  /// A question came back after the app had settled — a sign-in, a workspace
  /// switch. Put the screen back up for its full turn.
  ///
  /// A hold already standing is left alone: the clock belongs to the screen,
  /// and a second question arriving mid-swing must not restart it.
  void hold() {
    if (state) return;

    state = true;
  }

  /// The animation has been on screen for [minimum]. Let the router move on.
  void release() {
    if (!state) return;

    state = false;
  }
}
