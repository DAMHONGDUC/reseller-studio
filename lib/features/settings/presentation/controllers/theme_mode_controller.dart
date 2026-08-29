import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../mock_data/providers.dart';

/// Light, dark, or whatever the device says.
///
/// **Device-local, like the intro flag and unlike everything else the app
/// stores.** A theme is a property of the phone in the seller's hand, not of
/// the business — a seller who works on a bright shop floor and packs orders
/// at 1am wants opposite answers on their two devices, and syncing this to the
/// account would make one of them wrong.
///
/// That is also why Settings is reachable signed out: nothing here needs an
/// account.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final SharedPreferences? prefs = ref.watch(sharedPreferencesProvider).value;

    // Until preferences resolve, follow the device. Guessing light and
    // correcting a frame later is a white flash on a dark phone.
    if (prefs == null) return ThemeMode.system;

    return _parse(prefs.getString(PrefsKeyConstant.themeMode));
  }

  /// An unknown stored value falls back to [ThemeMode.system] rather than to a
  /// neighbour — the same rule a DTO follows for an unrecognised enum code.
  static ThemeMode _parse(String? stored) => switch (stored) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> select(ThemeMode mode) async {
    if (mode == state) return;

    state = mode;

    final SharedPreferences? prefs = ref.read(sharedPreferencesProvider).value;

    if (prefs == null) {
      SdLogger.warning(
        LogTagConstant.settings,
        'Could not persist theme — preferences not ready',
      );

      return;
    }

    try {
      await prefs.setString(PrefsKeyConstant.themeMode, mode.name);
      SdLogger.action(
        LogTagConstant.settings,
        'Theme changed',
        <String, String>{'mode': mode.name},
      );
    } catch (error, stackTrace) {
      // Logged rather than rethrown: the theme has already changed on screen
      // and the route the caller came from may be gone. The cost of the failed
      // write is one launch in the old theme.
      SdLogger.error(
        LogTagConstant.settings,
        'Persist theme failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, String>{'mode': mode.name},
      );
    }
  }
}

final NotifierProvider<ThemeModeController, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
