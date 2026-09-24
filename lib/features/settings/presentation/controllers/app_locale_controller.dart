import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../reseller_studio_app.dart';

/// The language the app shows, or null to follow the device.
///
/// Device-local for the same reason as `ThemeModeController`: two phones in
/// one business may be held by people who read different languages.
class AppLocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final SharedPreferences? prefs = ref.watch(sharedPreferencesProvider).value;

    if (prefs == null) return null;

    return parse(prefs.getString(PrefsKeyConstant.appLocale));
  }

  /// A code no longer shipped falls back to the device, never to a neighbour.
  static Locale? parse(String? stored) {
    for (final Locale locale in ResellerStudioApp.shippingLocales) {
      if (locale.languageCode == stored) return locale;
    }

    return null;
  }

  Future<void> select(Locale? locale) async {
    final String code = locale?.languageCode ?? 'system';
    final SharedPreferences? prefs = ref.read(sharedPreferencesProvider).value;

    if (locale == state) return;

    state = locale;

    if (prefs == null) {
      SdLogger.warning(
        LogTagConstant.settings,
        'Could not persist language — preferences not ready',
      );

      return;
    }

    try {
      if (locale == null) {
        await prefs.remove(PrefsKeyConstant.appLocale);
      } else {
        await prefs.setString(PrefsKeyConstant.appLocale, code);
      }
      SdLogger.action(
        LogTagConstant.settings,
        'Language changed',
        <String, String>{'locale': code},
      );
    } catch (error, stackTrace) {
      // Logged rather than rethrown, as for the theme: the screen already
      // shows the new language, and the cost is one launch in the old one.
      SdLogger.error(
        LogTagConstant.settings,
        'Persist language failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, String>{'locale': code},
      );
    }
  }
}

final NotifierProvider<AppLocaleController, Locale?> appLocaleProvider =
    NotifierProvider<AppLocaleController, Locale?>(AppLocaleController.new);
