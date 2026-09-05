import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_config.dart';

/// `app_config/current` — one document, read by every client.
///
/// **A missing or mistyped field reads as the fallback, never as a stricter
/// value.** The document is edited by hand in the console, so a typo is the
/// likely failure, and the two things it must not do are switch the paywall
/// off for everyone and lock everyone out of the app.
///
/// **The stored keys are snake_case; the Dart properties are not.** Owner's
/// rule, and this class is the whole of the translation — nothing above it
/// spells a field name, so the two conventions never have to meet twice.
final class AppConfigDto {
  static const String collection = 'app_config';
  static const String document = 'current';

  static const String _premiumEnabled = 'premium_enabled';
  static const String _minimumBuild = 'minimum_build';
  static const String _updateUrl = 'update_url';

  static AppConfig toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};
    final Object? enabled = data[_premiumEnabled];
    final Object? minimum = data[_minimumBuild];
    final Object? url = data[_updateUrl];

    return AppConfig(
      premiumEnabled: enabled is bool
          ? enabled
          : AppConfig.fallback.premiumEnabled,
      // A string where a number belongs falls back to forcing nothing, rather
      // than to some reading of `"12"` that locks out the wrong builds.
      minimumBuild: minimum is int ? minimum : AppConfig.fallback.minimumBuild,
      updateUrl: url is String && url.isNotEmpty ? url : null,
    );
  }
}
