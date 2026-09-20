import 'package:flutter/widgets.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';

/// How loud the owner's remote notice is.
///
/// **Two values, and neither one grants or refuses anything.** The notice
/// takes the whole screen either way; what this picks is the glyph and the
/// colour, so a planned outage does not arrive looking like a crash and a
/// crash does not arrive looking like a tip.
enum AppNoticeType {
  /// Something the seller should read before carrying on. Nothing is broken.
  warning,

  /// Something is broken. What an unreadable value falls back to, because the
  /// field it comes from is called `error_view` and the louder reading is the
  /// honest one for a notice nobody could type correctly.
  error;

  /// The stored string, read the way every other hand-typed field here is:
  /// trimmed, lowercased, and anything unrecognised landing on a value the
  /// app can render rather than on a crash.
  static AppNoticeType parse(Object? value) =>
      switch (value is String ? value.trim().toLowerCase() : '') {
        'warning' => AppNoticeType.warning,
        _ => AppNoticeType.error,
      };
}

/// What each type looks like — the one place a value becomes a glyph and a
/// tone, so a badge and a screen cannot drift apart.
///
/// `domain/` importing Flutter is the sanctioned exception for a display
/// extension; `CLAUDE.md` carries the rule.
extension AppNoticeTypeDisplay on AppNoticeType {
  /// The glyph over the notice. The app owns its icon set, which is why the
  /// design system asks for one rather than guessing.
  IconData get icon => switch (this) {
    AppNoticeType.warning => AppIconConstant.warning,
    AppNoticeType.error => AppIconConstant.error,
  };

  /// Which of the palette's two status colours the glyph takes.
  SdErrorToneV3 get tone => switch (this) {
    AppNoticeType.warning => SdErrorToneV3.warning,
    AppNoticeType.error => SdErrorToneV3.error,
  };
}
