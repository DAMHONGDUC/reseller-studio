import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/app_config.dart';
import '../../domain/entities/app_error_notice.dart';
import '../../domain/entities/app_update_policy.dart';
import '../../domain/enums/app_notice_type.dart';

/// `app_config/current` — one document, read by every client.
///
/// **A missing or mistyped field reads as the fallback, never as a stricter
/// value.** The document is edited by hand in the console, so a typo is the
/// likely failure, and the two things it must not do are lock everyone out of
/// the app and refuse an account over a value nobody typed.
///
/// **The stored keys are snake_case; the Dart properties are not.** Owner's
/// rule, and this class is the whole of the translation — nothing above it
/// spells a field name, so the two conventions never have to meet twice.
final class AppConfigDto {
  static const String collection = 'app_config';
  static const String document = 'current';

  static const String _forceUpdate = 'force_update';
  static const String _ios = 'ios';
  static const String _android = 'android';
  static const String _storeLink = 'store_link';
  static const String _buildName = 'build_name';
  static const String _buildNumber = 'build_number';
  static const String _enableForceUpdate = 'enable_force_update';
  static const String _premiumEmails = 'premium_emails';
  static const String _devModeEmails = 'dev_mode_emails';
  static const String _blockedEmails = 'blocked_emails';
  static const String _errorView = 'error_view';
  static const String _enable = 'enable';
  static const String _title = 'title';
  static const String _subtitle1 = 'subtitle_1';
  static const String _subtitle2 = 'subtitle_2';
  static const String _type = 'type';

  static AppConfig toEntity(DocumentSnapshot<Map<String, Object?>> doc) =>
      fromData(doc.data() ?? <String, Object?>{});

  /// The document's fields, once the snapshot is out of the way.
  ///
  /// **Split from [toEntity] so the parsing can be read at all.**
  /// `DocumentSnapshot` is sealed, so no test can build one and every shape
  /// this class defends against — a missing block, a bool that arrived as a
  /// string — would otherwise be unreachable from a test. Unwrapping is the
  /// whole of what [toEntity] does on its own.
  @visibleForTesting
  static AppConfig fromData(Map<String, Object?> data) {
    final Object? update = data[_forceUpdate];
    final Map<String, Object?> stores = update is Map<String, Object?>
        ? update
        : <String, Object?>{};

    return AppConfig(
      // The two stores are nested under one field rather than sitting at the
      // top level: a document with `ios` and `android` loose in it reads as a
      // config about platforms, when what it holds is one feature that happens
      // to be configured per store.
      ios: _policy(stores[_ios]),
      android: _policy(stores[_android]),
      premiumEmails: _emails(data[_premiumEmails]),
      devModeEmails: _emails(data[_devModeEmails]),
      blockedEmails: _emails(data[_blockedEmails]),
      errorNotice: _notice(data[_errorView]),
    );
  }

  /// The notice block, read the most defensively of anything here because it
  /// is the field that can replace the whole app.
  ///
  /// A missing block, a block of the wrong type, a switch that is not a bool
  /// and a title that is not a string all land on [AppErrorNotice.none],
  /// which shows nothing. Only a `true` beside a non-empty title puts a
  /// screen in front of every seller.
  static AppErrorNotice _notice(Object? value) {
    if (value is! Map<String, Object?>) return AppErrorNotice.none;

    final Object? enabled = value[_enable];

    return AppErrorNotice(
      enabled: enabled is bool ? enabled : AppErrorNotice.none.enabled,
      title: _line(value[_title]),
      subtitle1: _line(value[_subtitle1]),
      subtitle2: _line(value[_subtitle2]),
      type: AppNoticeType.parse(value[_type]),
    );
  }

  /// One line of the notice. Anything that is not a string reads as no line,
  /// and the surrounding whitespace of a value typed into a console field is
  /// not the owner's intent.
  static String _line(Object? value) => value is String ? value.trim() : '';

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
