import 'package:flutter/foundation.dart';

import 'app_env.dart';

/// Development switches that **cannot reach a release build**.
///
/// The values themselves come from `env/<flavour>.json` via [AppEnv]; this
/// class is the guard around them, and the split is the point:
///
/// - **[AppEnv] says what was asked for.** It is a JSON file, and anyone can
///   edit it — including editing `prod.json` by accident.
/// - **[DevFlags] says what is allowed.** Every flag here is `const` and
///   ANDed with `!kReleaseMode`.
///
/// Both halves of that guard matter:
///
/// - `const` means the expression folds at compile time, so a release build
///   contains `if (false)` and the tree-shaker deletes the branch and
///   everything only it reached. The bypass is not disabled in a shipped
///   binary; it is absent from it.
/// - `!kReleaseMode` means a `prod.json` with `"BYPASS_AUTH": true` still
///   ships an app with no bypass. A flag whose safety depends on the contents
///   of a config file is not a safety property.
///
/// **Never read `AppEnv.bypassAuthRequested` directly.** It is the unguarded
/// value, and it exists only so this file can guard it.
final class DevFlags {
  /// True in debug and profile builds, false in release.
  ///
  /// The gate for affordances that are *settings* rather than build flags —
  /// mock data is toggled from inside the running app, so it cannot be a
  /// `bool.fromEnvironment` and needs a runtime guard instead. Showing a user
  /// a fake business as if it were their own is worse than any crash, so the
  /// stored preference is overridden rather than trusted.
  static const bool isDebugOrProfile = !kReleaseMode;

  /// Skip authentication and enter the app as a fake signed-in user.
  ///
  /// ```sh
  /// fvm flutter run --dart-define-from-file=env/dev.json
  /// ```
  ///
  /// **This is a development affordance, not a guest mode.** The master
  /// plan's first principle is that login is mandatory and there is no guest
  /// mode, and `CLAUDE.md` hard rule 1 repeats it. It exists because the app
  /// has no Firebase project yet, so the login screen is otherwise a dead end
  /// and none of the app can be looked at.
  ///
  /// When it is on, nothing touches `FirebaseAuth` at all — see
  /// `isSignedInProvider`. That is deliberate: `FirebaseAuth.instance` throws
  /// `[core/no-app]` when `Firebase.initializeApp` has not run, which is
  /// exactly the situation this flag exists for.
  ///
  /// The app wears a visible banner while it is on (see `SellerOsApp`),
  /// because an invisible dev flag is one you demo to someone by accident.
  static const bool bypassAuth = AppEnv.bypassAuthRequested && !kReleaseMode;

  /// Whether mock data starts switched on.
  ///
  /// Defaults to following [bypassAuth] when the env file says nothing: a
  /// bypassed session has no project and no user, so live mode would show an
  /// empty app and a stream of permission errors. The two belong together.
  static const bool mockDataDefault =
      (AppEnv.mockDataDefault || AppEnv.bypassAuthRequested) && !kReleaseMode;

  /// Fine-grained console output. Debug builds only, whatever the env says.
  static const bool verboseLogging = AppEnv.verboseLogging && !kReleaseMode;

  /// The uid every workspace path and `createdBy` field uses while
  /// [bypassAuth] is on.
  ///
  /// A fixed, obviously-fake value rather than a random one, so that data
  /// written across two bypass sessions belongs to the same fake account and
  /// the app has something coherent to read back. It is also greppable: if
  /// this string ever turns up in a real Firestore project, a bypass build
  /// wrote to it.
  ///
  /// **Not in the env file on purpose.** It is a safety marker, not a
  /// setting, and making it configurable would let someone point a bypass
  /// build at a real uid.
  static const String bypassUid = 'dev-bypass-user';
}
