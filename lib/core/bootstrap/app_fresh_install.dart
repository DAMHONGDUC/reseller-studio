import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/index.dart';

import '../config/app_env.dart';
import '../constants/log_tag_constant.dart';
import '../constants/prefs_key_constant.dart';

/// What "a fresh install" means on this device, and how the app finds out it
/// needs one.
///
/// The dev and prod flavours share a sandbox wherever they share a bundle id,
/// so installing one over the other leaves the new binary reading the old
/// one's signed-in session, preferences and cached documents — a dev account
/// pointed at the real project, or the reverse. [SdFreshInstallGuard] makes
/// the comparison; this class is the half that touches the device, and it is
/// the only place that knows what has to go.
///
/// **Every step guards itself.** The wipe runs before the app's first frame,
/// where an uncaught throw is not an error screen but an app that never
/// starts — and a device that lost its Firestore cache but kept its session
/// is a worse state than one where both went.
final class AppFreshInstall {
  /// The wiring handed to [SdDevWrapper]. One instance, so a rebuild of the
  /// app widget does not hand the guard a new policy every frame.
  static final SdFreshInstallPolicy policy = SdFreshInstallPolicy(
    readLastEnv: _readLastEnv,
    writeEnv: _writeEnv,
    wipe: _wipe,
  );

  /// Which environment the last launch recorded, or null if none did.
  static Future<String?> _readLastEnv() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      return prefs.getString(PrefsKeyConstant.lastEnv);
    } catch (error, stackTrace) {
      // Null reads as a first launch, which wipes nothing — the safe way to
      // be wrong here, since the alternative deletes a seller's session over
      // a preferences plugin that did not answer.
      SdLogger.error(
        LogTagConstant.freshInstall,
        'Could not read the recorded environment',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  static Future<void> _writeEnv(String envName) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString(PrefsKeyConstant.lastEnv, envName);

      SdLogger.info(
        LogTagConstant.freshInstall,
        'Environment recorded',
        <String, String>{'env': envName},
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.freshInstall,
        'Could not record the environment',
        error: error,
        stackTrace: stackTrace,
        data: <String, String>{'env': envName},
      );
    }
  }

  /// Take the device back to what a fresh install would have had.
  ///
  /// The order is deliberate: sign out first so nothing is still writing,
  /// then drop the cached documents that session pulled down, then the
  /// preferences that point at them.
  static Future<void> _wipe(String? previous, String current) async {
    SdLogger.action(
      LogTagConstant.freshInstall,
      'Wipe device for environment change',
      <String, String>{'previous': previous ?? '—', 'current': current},
    );

    await _signOut();

    await _clearFirestoreCache();

    await _clearPreferences();
  }

  static Future<void> _signOut() async {
    if (!_hasFirebase) {
      return;
    }

    try {
      // Google keeps its own account selection outside Firebase, so signing
      // out of one leaves the other offering the previous seller's account.
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();

      SdLogger.info(LogTagConstant.freshInstall, 'Signed out');
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.freshInstall,
        'Could not sign out during the wipe',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Drop every document Firestore cached for the other environment.
  ///
  /// **`terminate` first, and this only works before anything reads.**
  /// `clearPersistence` throws `failed-precondition` while the client is
  /// running, which is why the guard holds the app's first frame back rather
  /// than wiping alongside it.
  static Future<void> _clearFirestoreCache() async {
    if (!_hasFirebase) {
      return;
    }

    try {
      await FirebaseFirestore.instance.terminate();
      await FirebaseFirestore.instance.clearPersistence();

      SdLogger.info(LogTagConstant.freshInstall, 'Firestore cache cleared');
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.freshInstall,
        'Could not clear the Firestore cache',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Everything device-local goes, the onboarding flag included — a fresh
  /// install is exactly what this is pretending to be.
  static Future<void> _clearPreferences() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.clear();

      SdLogger.info(LogTagConstant.freshInstall, 'Preferences cleared');
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.freshInstall,
        'Could not clear preferences',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Whether there is a Firebase app to sign out of at all.
  ///
  /// A build with no config never called `initializeApp`, and reaching for
  /// `FirebaseAuth.instance` there throws `[core/no-app]` — the same guard
  /// `firebaseReadyProvider` makes for the rest of the app.
  static bool get _hasFirebase =>
      AppEnv.hasFirebaseConfig && Firebase.apps.isNotEmpty;
}
