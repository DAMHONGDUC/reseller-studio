import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/index.dart';

import '../analytics/app_analytics.dart';
import '../config/app_env.dart';
import '../constants/log_tag_constant.dart';
import '../logging/firebase_crash_reporter.dart';
import '../providers/shared_preferences_provider.dart';
import 'app_startup_failure.dart';

/// This app's startup steps — the SDKs, and nothing about how they are run.
///
/// [SdBootstrap] owns the guarded zone, the ordering, the per-step `try`, the
/// logging and the three framework error hooks; the design system imports no
/// vendor SDK, so what actually comes up arrives as [SdBootstrapStep]s. Same
/// split as `SdCrashReporter` and `SdFreshInstallHost`.
///
/// **Firebase goes first** so Crashlytics is attached before anything else can
/// fail. Every step here runs before `runApp`, where an unhandled throw does
/// not show an error screen — it stops the app from starting at all — so each
/// one is written to leave the app usable when it fails.
///
/// **The fresh-install wipe is deliberately not a step.** `SplashScreen` runs
/// it, because before `runApp` the only thing on screen is the platform launch
/// image and a wipe that takes a second looks like a hang.
///
/// **A step that fails does not stop the launch, and one of them still can
/// end it.** `SdBootstrap` guards each step and always calls `runApp`, so the
/// app opens whatever went wrong; [onStepFailed] is where this app decides
/// whether what it opens into is the router or `StartupErrorScreen`.
/// [StartupFailurePolicy] holds that judgement.
///
/// **Preferences are the one exception to that, and they have to be.** They
/// decide how the app *looks* — `themeModeProvider` reads them — and the theme
/// is set on `MaterialApp`, above the splash, so there is no screen that could
/// be shown while they load: the app would paint a guess and correct it a
/// frame later, which is a white flash on a seller who chose dark. They are a
/// local plugin call, not a network round trip, so this costs milliseconds.
final class AppBootstrap {
  /// Starts the app.
  static Future<void> init(Widget Function() builder) => SdBootstrap.run(
    logTag: LogTagConstant.bootstrap,
    builder: builder,
    steps: <SdBootstrapStep>[
      SdBootstrapStep(name: 'Preferences', run: _loadPreferences),
      SdBootstrapStep(name: 'Firebase', run: _initializeFirebase),
      SdBootstrapStep(name: 'Google Sign-In', run: _initializeGoogleSignIn),
      SdBootstrapStep(name: 'Billing', run: _initializeBilling),
      SdBootstrapStep(name: 'Portrait orientation', run: lockPortrait),
      SdBootstrapStep(name: 'Edge-to-edge', run: _goEdgeToEdge),
      SdBootstrapStep(name: 'Environment', run: _logEnvironment),
    ],
    onStepFailed: _recordFailure,
  );

  /// The failure the app cannot open past, or null on a normal launch.
  ///
  /// Read by `ResellerStudioApp` before it builds anything else, so nothing
  /// downstream has to know a step failed.
  static AppStartupFailure? get startupFailure => _startupFailure;

  static AppStartupFailure? _startupFailure;

  /// Keep the first fatal failure, and let every other one through.
  ///
  /// `SdBootstrap` has already logged the throw itself; the line below is the
  /// separate fact that the app is about to show an error screen instead of
  /// the router, which is what somebody reading the console is looking for.
  ///
  /// **The first, not the last**: a step that fails because Firebase did is a
  /// consequence, and naming it would send the reader to the wrong SDK.
  static void _recordFailure(SdBootstrapStep step, Object error) {
    if (_startupFailure != null || !StartupFailurePolicy.isFatal(error)) return;

    _startupFailure = AppStartupFailure(step: step.name, error: error);

    SdLogger.error(
      LogTagConstant.bootstrap,
      'Fatal startup failure — the app opens on the error screen',
      error: error,
      data: <String, String>{'step': step.name},
    );
  }

  /// What `main.dart` hands the `ProviderScope`, so the first frame already
  /// knows what the device was told to look like.
  ///
  /// Empty when the plugin refused: the app still starts, `themeModeProvider`
  /// follows the device, and the cost is the flash this exists to remove.
  static List<Override> get overrides {
    final SharedPreferences? loaded = _preferences;

    if (loaded == null) return const <Override>[];

    // A synchronous return, so the provider is `AsyncData` on its first read
    // rather than one microtask of `AsyncLoading` — which is the frame the
    // flash happened in.
    return <Override>[
      sharedPreferencesProvider.overrideWith((Ref ref) => loaded),
    ];
  }

  static SharedPreferences? _preferences;

  static Future<void> _loadPreferences() async =>
      _preferences = await SharedPreferences.getInstance();

  /// Kept public for the platform-channel test; startup is its only caller.
  @visibleForTesting
  static Future<void> lockPortrait() => SystemChrome.setPreferredOrientations(
    const <DeviceOrientation>[DeviceOrientation.portraitUp],
  );

  /// Let the app draw under the system bars.
  ///
  /// Android only in effect — iOS is already edge to edge. Without it the
  /// floating glass tab bar has an opaque system strip under it instead of the
  /// content it is supposed to refract, and `extendBody` buys nothing.
  ///
  /// The *style* of those bars is not set here: that is
  /// `AppTheme.statusBarStyle`, read through the theme, because a
  /// `SystemChrome` call made once at startup cannot follow a device switching
  /// between light and dark.
  static Future<void> _goEdgeToEdge() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  /// Bring Firebase up, and attach Crashlytics if it comes up.
  ///
  /// **A throw here is [SdBootstrap]'s to catch, and it prints the stack
  /// rather than reporting it** — the reporter is what just failed. The app
  /// still starts, `SdCrashReporter` stays a no-op, and the seller sees a
  /// working offline app rather than a white screen. Standing in a store with
  /// no signal is a normal Tuesday, not an error state.
  ///
  /// **Two throws here are not survivable, and neither is about the network.**
  /// A duplicate app leaves the process on an instance this build never
  /// configured; a [FlavorConfigMismatch] leaves it on a project this build
  /// was never meant to touch. Both get the error screen rather than five
  /// tabs onto the wrong backend — [StartupFailurePolicy] names them.
  ///
  /// **The project id is checked before Crashlytics is attached**, so a build
  /// pointed at the wrong project cannot also send its crashes there.
  static Future<void> _initializeFirebase() async {
    if (!AppEnv.hasFirebaseConfig) {
      // Distinct from a thrown init failure on purpose: "no project
      // configured" and "configured but unreachable" look identical from the
      // exception and want completely different responses.
      SdLogger.warning(
        LogTagConstant.bootstrap,
        'No Firebase config in this build — running without a backend. '
        'Fill the FIREBASE_* keys in env/${AppEnv.flavor.name}.json once '
        '`flutterfire configure` has been run.',
      );

      return;
    }

    await Firebase.initializeApp();

    final String nativeProjectId = Firebase.app().options.projectId;

    // The two halves of a build's config, compared where they finally meet.
    if (nativeProjectId != AppEnv.firebaseProjectId) {
      throw FlavorConfigMismatch(
        expected: AppEnv.firebaseProjectId,
        actual: nativeProjectId,
      );
    }

    final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

    // Nothing is collected in debug: a crash while developing is one the
    // developer is already looking at, and shipping it to the dashboard
    // buries the real ones from real users.
    await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);

    SdCrashReporter.attach(FirebaseCrashReporter(crashlytics));
    AppAnalytics.attach(FirebaseAnalytics.instance);
  }

  /// Configure Google Sign-In before any button can call it.
  ///
  /// `google_sign_in` 7 requires `initialize` to have completed before
  /// `authenticate`, and sign-in is one of only two ways into this app
  /// (`CLAUDE.md` hard rule 1) — so doing it lazily on the first tap would put
  /// a round trip in front of the seller at the worst moment.
  ///
  /// A failure leaves the Google button broken and the Apple one working,
  /// which is a far better outcome than an app that does not start.
  static Future<void> _initializeGoogleSignIn() async {
    await GoogleSignIn.instance.initialize(
      // Empty means "read it from the platform config file"
      // (`GoogleService-Info.plist` / `google-services.json`), which is what
      // `flutterfire configure` writes. The env keys exist to override that
      // for a build whose bundle id differs from the Firebase app's.
      clientId: AppEnv.googleSignInClientIdIos.isEmpty
          ? null
          : AppEnv.googleSignInClientIdIos,
      serverClientId: AppEnv.googleSignInServerClientId.isEmpty
          ? null
          : AppEnv.googleSignInServerClientId,
    );
  }

  /// Configure RevenueCat, if this build has a key for it.
  ///
  /// Skipped silently-but-logged when it does not, which is the app's normal
  /// condition until the owner sets billing up: `subscriptionRepositoryProvider`
  /// then hands out the unconfigured implementation and every seller reads as
  /// Free. Configuring with an empty key would throw here instead.
  ///
  /// **No user identifier is passed.** RevenueCat generates an anonymous id;
  /// linking it to the Firebase uid is a `logIn` call that belongs after
  /// sign-in, not at startup where there is no user yet.
  static Future<void> _initializeBilling() async {
    final String key = defaultTargetPlatform == TargetPlatform.android
        ? AppEnv.revenueCatApiKeyAndroid
        : AppEnv.revenueCatApiKeyIos;

    if (key.isEmpty) {
      SdLogger.warning(
        LogTagConstant.bootstrap,
        'No RevenueCat key in this build — every seller reads as Free. '
        'Fill the RevenueCat build configuration for this flavor.',
      );

      return;
    }

    await Purchases.configure(PurchasesConfiguration(key));

    // A key alone is not enough to sell anything: the repository needs the
    // entitlement and the offering too, and without them the paywall is empty
    // while this step still reads as a success.
    if (AppEnv.missingBillingKeys.isNotEmpty) {
      SdLogger.warning(
        LogTagConstant.bootstrap,
        'Billing configuration incomplete — the paywall will list nothing',
        <String, List<String>>{'missingKeys': AppEnv.missingBillingKeys},
      );
    }
  }

  /// Log which configuration this build is running on.
  ///
  /// **Names keys, never values** — hard rule 9.
  static Future<void> _logEnvironment() async {
    SdLogger.info(LogTagConstant.bootstrap, 'Environment', <String, String>{
      'config': AppEnv.summary,
    });

    if (kReleaseMode && AppEnv.missingReleaseKeys.isNotEmpty) {
      // A release build with no Firebase config will fail on every screen.
      // Say so once, naming every missing key at once rather than one per
      // rebuild.
      SdLogger.warning(
        LogTagConstant.bootstrap,
        'Release build is missing required env keys',
        <String, String>{'keys': AppEnv.missingReleaseKeys.join(', ')},
      );
    }
  }
}
