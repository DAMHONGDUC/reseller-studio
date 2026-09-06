import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../config/app_env.dart';
import '../constants/log_tag_constant.dart';
import '../constants/prefs_key_constant.dart';

/// What "a fresh install" means on this device.
///
/// The dev and prod flavours share a sandbox wherever they share a bundle id,
/// so installing one over the other leaves the new binary reading the old
/// one's signed-in session, preferences and cached documents — a dev account
/// pointed at the real project, or the reverse. [SdFreshInstall] decides;
/// what is left here is the only part that is this app's — which SDKs have
/// something to drop, and the `shared_preferences` behind the store.
///
/// **There is no device-scoped store.** Nothing this app writes outlives a
/// delete, so a reinstall is a first install already and that half of the
/// check cannot fire.
final class AppFreshInstall {
  const AppFreshInstall._();

  /// Take the device back to a fresh install if it needs it.
  ///
  /// Order matters: sign out first so nothing is still writing, then drop the
  /// cached documents that session pulled down. Emptying preferences is
  /// appended by [SdFreshInstall] and takes the onboarding flag with it,
  /// because that is what a fresh install is.
  static Future<void> run() => SdFreshInstall.run(
    logTag: LogTagConstant.freshInstall,
    buildStamp: AppEnv.flavor.name,
    installScoped: const _PrefsStore(),
    // The key this app has always used, so an install that predates the
    // merge already carries a valid stamp and reads as a normal launch.
    stampKey: PrefsKeyConstant.lastEnv,
    wipe: <SdDeviceWipeStep>[
      SdDeviceWipeStep(name: 'Sign out', when: _hasFirebase, run: _signOut),
      SdDeviceWipeStep(
        name: 'Clear Firestore cache',
        when: _hasFirebase,
        run: _clearFirestoreCache,
      ),
    ],
  );

  static Future<void> _signOut() async {
    // Google keeps its own account selection outside Firebase, so signing out
    // of one leaves the other offering the previous seller's account.
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }

  /// Drop every document Firestore cached for the other environment.
  ///
  /// **`terminate` first, and this only works before anything reads.**
  /// `clearPersistence` throws `failed-precondition` while the client is
  /// running, which is why this runs before `runApp` rather than alongside the
  /// first screen.
  static Future<void> _clearFirestoreCache() async {
    await FirebaseFirestore.instance.terminate();
    await FirebaseFirestore.instance.clearPersistence();
  }

  /// Whether there is a Firebase app to sign out of at all.
  ///
  /// A build with no config never called `initializeApp`, and reaching for
  /// `FirebaseAuth.instance` there throws `[core/no-app]` — the same guard
  /// `firebaseReadyProvider` makes for the rest of the app.
  static bool _hasFirebase() =>
      AppEnv.hasFirebaseConfig && Firebase.apps.isNotEmpty;
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
