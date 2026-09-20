import '../config/app_env.dart';

/// A startup step that failed in a way the app cannot run past.
///
/// **Almost no failure is one of these, and that is the point.** `SdBootstrap`
/// guards every step so the launch survives it, and most of what can go wrong
/// leaves a usable app: no Firebase config is an offline build, a broken
/// Google Sign-In leaves Apple working, no billing key reads every seller as
/// Free. Those are logged and the app opens.
///
/// What this names is the other case — the app came up in a state it cannot
/// trust, so opening it would hand the seller screens whose data is a guess.
/// [StartupFailurePolicy] is the one place that decides which is which, and
/// `StartupErrorScreen` is what the seller sees instead of the router.
final class AppStartupFailure {
  const AppStartupFailure({required this.step, required this.error});

  /// The `SdBootstrapStep.name` that threw — 'Firebase', 'Billing'.
  final String step;

  /// What was thrown, unmodified, for the log and for a debug build's detail
  /// row. It never reaches a release screen (hard rule 6).
  final Object error;

  /// The raw failure as one line, for whoever can act on it.
  String get detail => '$step: $error';
}

/// The two halves of a build's configuration name different Firebase
/// projects.
///
/// `env/<flavour>.json` is compiled in by `--dart-define-from-file`;
/// `GoogleService-Info.plist` and `google-services.json` are read by the
/// native SDK. `melos run prepare-env-<flavour>` installs both, and nothing
/// else ties them together — so a run started before that script, or after
/// the other flavour's, compiles, installs, launches and writes a dev
/// session into the production Firestore. Neither half is wrong on its own,
/// which is why nothing failed.
///
/// The release lane already refuses this (`sd_verify_flavor_config`). This is
/// the same question asked where it actually bites: `fvm flutter run` on a
/// developer's machine.
final class FlavorConfigMismatch implements Exception {
  const FlavorConfigMismatch({required this.expected, required this.actual});

  /// The project `env/<flavour>.json` names.
  final String expected;

  /// The project the native SDK came up on.
  final String actual;

  @override
  String toString() =>
      'env/${AppEnv.flavor.name}.json is $expected, but the native config is '
      '$actual. Run `melos run prepare-env-${AppEnv.flavor.name}`.';
}

/// Which startup failures stop the app, and which ones it opens without.
///
/// The class *is* the policy, so what it matches on lives here rather than in
/// a constants file — it is the algorithm, not configuration about it.
final class StartupFailurePolicy {
  /// True when [error] leaves the app in a state it cannot open into.
  ///
  /// **Exactly one failure qualifies**, and it is deliberately not "anything
  /// the Firebase step threw": every other way that step fails leaves a usable
  /// app. No config is an offline build, a project that could not be reached
  /// is a seller standing in a store with no signal, a broken Google Sign-In
  /// leaves Apple working. All of those open the app.
  ///
  /// [FlavorConfigMismatch] is the other kind, and the only one. Nothing is
  /// unreachable — that is the problem: the app would work perfectly, against
  /// the wrong project.
  static bool isFatal(Object error) => error is FlavorConfigMismatch;
}
