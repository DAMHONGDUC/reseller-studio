import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../config/app_env.dart';
import '../constants/log_tag_constant.dart';
import '../constants/prefs_key_constant.dart';

/// This app's half of the fresh-install check — the vendor calls, and nothing
/// else.
///
/// [SdFreshInstall] owns the question and the order; the design system imports
/// no Firebase SDK and no storage plugin, so what a wipe *does* on this device
/// arrives through [SdFreshInstallHost]. Same split as `SdCrashReporter`.
///
/// **There is no device-scoped store.** Nothing this app writes outlives a
/// delete, so a reinstall is a first install already and that half of the
/// check cannot fire. That is the difference from the sibling app, whose iOS
/// Keychain kept a session across one.
final class AppFreshInstall implements SdFreshInstallHost {
  const AppFreshInstall();

  /// Take the device back to a fresh install if it needs it.
  static Future<SdFreshInstallOutcome> run() => SdFreshInstall.run(
    logTag: LogTagConstant.freshInstall,
    buildStamp: AppEnv.flavor.name,
    installScoped: const _PrefsStore(),
    host: const AppFreshInstall(),
    // The key this app has always used, so an install that predates the merge
    // already carries a valid stamp and reads as a normal launch.
    stampKey: PrefsKeyConstant.lastEnv,
  );

  /// A build with no config never called `initializeApp`, and reaching for
  /// `FirebaseAuth.instance` there throws `[core/no-app]` — the same guard
  /// `firebaseReadyProvider` makes for the rest of the app.
  @override
  bool get isBackendReady =>
      AppEnv.hasFirebaseConfig && Firebase.apps.isNotEmpty;

  @override
  Future<void> signOut() async {
    // Google keeps its own account selection outside Firebase, so signing out
    // of one leaves the other offering the previous seller's account.
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }

  /// **`terminate` first, and this only works before anything reads.**
  /// `clearPersistence` throws `failed-precondition` while the client is
  /// running, which is why `FreshInstallGate` sits above everything that opens
  /// a stream.
  @override
  Future<void> clearCache() async {
    await FirebaseFirestore.instance.terminate();
    await FirebaseFirestore.instance.clearPersistence();
  }
}

/// `shared_preferences` behind the store the design system asks for.
class _PrefsStore implements SdInstallScopedStore {
  const _PrefsStore();

  @override
  Future<Iterable<String>> getKeys() async =>
      (await SharedPreferences.getInstance()).getKeys();

  @override
  Future<Object?> get(String key) async =>
      (await SharedPreferences.getInstance()).get(key);

  @override
  Future<String?> getString(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> setString(String key, String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);

  @override
  Future<void> remove(String key) async =>
      (await SharedPreferences.getInstance()).remove(key);

  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).clear();
}

/// The check, as something the widget tree can wait on.
///
/// A `FutureProvider` so it runs exactly once per launch however many times
/// the gate rebuilds, and so the gate reads it as a plain `AsyncValue` rather
/// than holding a future in `State`.
final FutureProvider<SdFreshInstallOutcome> freshInstallProvider =
    FutureProvider<SdFreshInstallOutcome>(
      (Ref ref) => AppFreshInstall.run(),
    );
