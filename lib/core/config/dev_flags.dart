import 'package:flutter/foundation.dart';

/// Build-time switches that exist for development and **cannot reach a
/// release build**.
///
/// Every flag here is `const`, and every one is ANDed with `!kReleaseMode`.
/// Both halves matter:
///
/// - `const` means the expression folds at compile time, so a release build
///   contains `if (false)` and the tree-shaker deletes the branch and
///   everything only it reached. The bypass is not disabled in a shipped
///   binary; it is absent from it.
/// - `!kReleaseMode` means passing `--dart-define=BYPASS_AUTH=true` to a
///   release build does nothing. A flag whose safety depends on the person
///   typing the build command is not a safety property.
///
/// A flag added here without both is a flag that ships.
abstract final class DevFlags {
  /// Skip authentication and enter the app as a fake signed-in user.
  ///
  /// ```sh
  /// fvm flutter run --dart-define=BYPASS_AUTH=true
  /// ```
  ///
  /// **This is a development affordance, not a guest mode.** The master plan's
  /// first principle is that login is mandatory and there is no guest mode,
  /// and `CLAUDE.md` hard rule 1 repeats it. This exists because the app has
  /// no Firebase project yet: without it the login screen is a dead end and
  /// none of the app can be looked at.
  ///
  /// When it is on, nothing touches `FirebaseAuth` at all — see
  /// `isSignedInProvider`. That is deliberate: `FirebaseAuth.instance` throws
  /// `[core/no-app]` when `Firebase.initializeApp` has not run, which is
  /// exactly the situation this flag exists for.
  ///
  /// The app wears a visible banner while it is on (see `SellerOsApp`),
  /// because an invisible dev flag is one you demo to someone by accident.
  static const bool bypassAuth =
      bool.fromEnvironment('BYPASS_AUTH') && !kReleaseMode;

  /// The uid every workspace path and `createdBy` field uses while
  /// [bypassAuth] is on.
  ///
  /// A fixed, obviously-fake value rather than a random one, so that data
  /// written across two bypass sessions belongs to the same fake account and
  /// the app has something coherent to read back. It is also greppable: if
  /// this string ever turns up in a real Firestore project, a bypass build
  /// wrote to it.
  static const String bypassUid = 'dev-bypass-user';
}
