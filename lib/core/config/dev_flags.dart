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
  /// The floor under `devModeEnabledProvider`, which is what every runtime
  /// call site reads: a debug build always has the developer affordances, and
  /// a release build has them only when `app_config` names the account.
  static const bool isDebugOrProfile = !kReleaseMode;

  /// Fine-grained console output. Debug builds only, whatever the env says.
  static const bool verboseLogging = AppEnv.verboseLogging && !kReleaseMode;
}
