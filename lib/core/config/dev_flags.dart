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
///   everything only it reached. A dev affordance is not disabled in a
///   shipped binary; it is absent from it.
/// - `!kReleaseMode` means a `prod.json` with a switch turned on still ships
///   an app without it. A flag whose safety depends on the contents of a
///   config file is not a safety property.
///
/// **The auth bypass is gone** — it entered the app as a fake signed-in user
/// so that the login screen was not a dead end before Firebase existed. The
/// five tabs now render empty without an account (hard rule 1), so that
/// reason expired and the flag with it. There is no guest mode and no way in
/// but Apple or Google.
final class DevFlags {
  /// True in debug and profile builds, false in release.
  ///
  /// The gate for affordances that are *settings* rather than build flags —
  /// mock data is toggled from inside the running app, so it cannot be a
  /// `bool.fromEnvironment` and needs a runtime guard instead. Showing a user
  /// a fake business as if it were their own is worse than any crash, so the
  /// stored preference is overridden rather than trusted.
  static const bool isDebugOrProfile = !kReleaseMode;

  /// Whether mock data starts switched on. **Off unless the env file asks for
  /// it** — owner's rule.
  ///
  /// It used to follow the auth bypass, on the grounds that a bypassed
  /// session had no project and would otherwise show an empty app. That
  /// reasoning is now the argument against it: the app renders its five tabs
  /// empty before sign-in by design (hard rule 1), so an empty app is a real
  /// state worth looking at — and a default that quietly replaced it with a
  /// fake business meant nobody was developing against what a new seller
  /// actually sees.
  ///
  /// Turning it on is `"MOCK_DATA_DEFAULT": true` in the env file, or the
  /// switch in More → Settings, which is where it is meant to be reached from.
  static const bool mockDataDefault = AppEnv.mockDataDefault && !kReleaseMode;

  /// Fine-grained console output. Debug builds only, whatever the env says.
  static const bool verboseLogging = AppEnv.verboseLogging && !kReleaseMode;
}
