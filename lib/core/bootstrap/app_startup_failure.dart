import 'package:firebase_core/firebase_core.dart';

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
/// The class *is* the policy, so the codes it matches on live here rather than
/// in a constants file — they are the algorithm, not configuration about it.
final class StartupFailurePolicy {
  /// Firebase was initialized twice: the SDK refuses the second call, and the
  /// app is left with an instance nobody in this process configured.
  ///
  /// Everything downstream — auth, Firestore, Crashlytics — hangs off that
  /// instance, so the honest outcome is to say so rather than to open five
  /// tabs onto a backend this build never set up.
  static const String _duplicateAppCode = 'duplicate-app';

  /// True when [error] leaves the app in a state it cannot open into.
  ///
  /// Deliberately a list of named failures rather than "anything the Firebase
  /// step threw": a build that simply could not reach Firebase is a seller
  /// standing in a store with no signal, and that one gets the app.
  ///
  /// [FlavorConfigMismatch] is the other kind: nothing is unreachable, and
  /// that is the problem — the app would work perfectly against the wrong
  /// project.
  static bool isFatal(Object error) =>
      error is FlavorConfigMismatch ||
      (error is FirebaseException && error.code == _duplicateAppCode);
}
