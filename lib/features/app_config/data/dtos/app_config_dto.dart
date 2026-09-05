import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_config.dart';

/// `app_config/current` — one document, read by every client.
///
/// **A missing or mistyped field reads as the fallback, never as false.** The
/// document is edited by hand in the console, so a typo is the likely failure,
/// and the one thing it must not do is switch the paywall off for everyone.
final class AppConfigDto {
  static const String collection = 'app_config';
  static const String document = 'current';

  static const String _premiumEnabled = 'premiumEnabled';

  static AppConfig toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Object? enabled = doc.data()?[_premiumEnabled];

    return AppConfig(
      premiumEnabled: enabled is bool
          ? enabled
          : AppConfig.fallback.premiumEnabled,
    );
  }
}
