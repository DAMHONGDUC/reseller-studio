import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/index.dart';

import '../config/app_env.dart';
import '../constants/log_tag_constant.dart';
import '../constants/prefs_key_constant.dart';

/// What "a fresh install" means on this device.
///
/// The dev and prod flavours share a sandbox wherever they share a bundle id,
/// so installing one over the other leaves the new binary reading the old
/// one's signed-in session, preferences and cached documents — a dev account
/// pointed at the real project, or the reverse. `SdFreshInstallGuard` makes
/// the comparison and [SdFreshInstall] runs the wipe; what is left here is
/// the only part that is this app's — which SDKs have something to drop, and
/// the `shared_preferences` behind [SdFreshInstallStore].
final class AppFreshInstall {
  const AppFreshInstall._();

  /// The wiring handed to `SdDevWrapper`. One instance, so a rebuild of the
  /// app widget does not hand the guard a new policy every frame.
  ///
  /// Order matters: sign out first so nothing is still writing, then drop the
  /// cached documents that session pulled down. Preferences go last and
  /// [SdFreshInstall] does that itself.
  static final SdFreshInstallPolicy policy = SdFreshInstall.policy(
    logTag: LogTagConstant.freshInstall,
    envKey: PrefsKeyConstant.lastEnv,
    store: const _PrefsStore(),
    steps: <SdDeviceWipeStep>[
      SdDeviceWipeStep(
        name: 'Sign out',
        when: _hasFirebase,
        run: _signOut,
      ),
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
  /// running, which is why the guard holds the app's first frame back rather
  /// than wiping alongside it.
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
///
/// Clearing takes the onboarding flag with it, deliberately — a fresh install
/// is exactly what this is pretending to be.
class _PrefsStore implements SdFreshInstallStore {
  const _PrefsStore();

  @override
  Future<String?> readString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(key, value);
  }

  @override
  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}
