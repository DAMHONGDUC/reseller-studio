import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_config.dart';
import '../../domain/entities/app_update_policy.dart';

/// `app_config/current` — one document, read by every client.
///
/// **A missing or mistyped field reads as the fallback, never as a stricter
/// value.** The document is edited by hand in the console, so a typo is the
/// likely failure, and the three things it must not do are switch the paywall
/// off for everyone, lock everyone out of the app, and refuse an account over
/// a value nobody typed.
///
/// **The stored keys are snake_case; the Dart properties are not.** Owner's
/// rule, and this class is the whole of the translation — nothing above it
/// spells a field name, so the two conventions never have to meet twice.
final class AppConfigDto {
  static const String collection = 'app_config';
  static const String document = 'current';

  static const String _premiumEnabled = 'premium_enabled';
  static const String _ios = 'ios';
  static const String _android = 'android';
  static const String _storeLink = 'store_link';
  static const String _buildName = 'build_name';
  static const String _buildNumber = 'build_number';
  static const String _enableForceUpdate = 'enable_force_update';
  static const String _premiumEmails = 'premium_emails';
  static const String _devModeEmails = 'dev_mode_emails';
  static const String _blockedEmails = 'blocked_emails';

  static AppConfig toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};
    final Object? enabled = data[_premiumEnabled];

    return AppConfig(
      premiumEnabled: enabled is bool
          ? enabled
          : AppConfig.fallback.premiumEnabled,
      ios: _policy(data[_ios]),
      android: _policy(data[_android]),
      premiumEmails: _emails(data[_premiumEmails]),
      devModeEmails: _emails(data[_devModeEmails]),
      blockedEmails: _emails(data[_blockedEmails]),
    );
  }

  /// One store's block, read the same defensive way as everything else here:
  /// a missing object, a missing field or a value of the wrong type all land
  /// on [AppUpdatePolicy.none], which forces nothing.
  static AppUpdatePolicy _policy(Object? value) {
    if (value is! Map<String, Object?>) return AppUpdatePolicy.none;

    final Object? enabled = value[_enableForceUpdate];
    final Object? build = value[_buildNumber];
    final Object? name = value[_buildName];
    final Object? link = value[_storeLink];

    return AppUpdatePolicy(
      forceUpdateEnabled: enabled is bool
          ? enabled
          : AppUpdatePolicy.none.forceUpdateEnabled,
      // A string where a number belongs falls back to forcing nothing, rather
      // than to some reading of `"41"` that stops the wrong builds.
      buildNumber: build is int ? build : AppUpdatePolicy.none.buildNumber,
      buildName: name is String && name.isNotEmpty ? name : null,
      storeLink: link is String && link.isNotEmpty ? link : null,
    );
  }

  /// Normalises here rather than at every comparison: the document is typed by
  /// hand, so ` Owner@Gmail.com ` is the expected shape of a correct entry and
  /// a case-sensitive match would silently grant and block nobody.
  ///
  /// Anything that is not a list of non-empty strings reads as no entries —
  /// the same direction as every other malformed field.
  static Set<String> _emails(Object? value) {
    if (value is! List<Object?>) return const <String>{};

    return value
        .whereType<String>()
        .map((String email) => email.trim().toLowerCase())
        .where((String email) => email.isNotEmpty)
        .toSet();
  }
}
