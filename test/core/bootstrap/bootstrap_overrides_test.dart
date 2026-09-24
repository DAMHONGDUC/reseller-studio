import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/constants/prefs_key_constant.dart';
import 'package:reseller_studio/core/providers/shared_preferences_provider.dart';
import 'package:reseller_studio/features/more/presentation/controllers/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **The theme has to be right on the first frame, not on the second.**
///
/// `themeMode` is set on `MaterialApp`, above the splash, so there is no
/// screen that could be shown while preferences load — the app paints a guess
/// and corrects it, which is a white flash on a seller who chose dark and
/// whose *device* is light. The bootstrap loads preferences before `runApp`
/// and hands them to the scope, so the very first read is already `AsyncData`.
Future<SharedPreferences> _prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);

  return SharedPreferences.getInstance();
}

ThemeMode _firstFrameTheme(List<Override> overrides) {
  final ProviderContainer container = ProviderContainer(overrides: overrides);

  addTearDown(container.dispose);

  return container.read(themeModeProvider);
}

void main() {
  test('a preloaded store gives the chosen theme immediately', () async {
    final SharedPreferences prefs = await _prefsWith(<String, Object>{
      PrefsKeyConstant.themeMode: 'dark',
    });

    // What `AppBootstrap.overrides` hands the scope: a synchronous return, so
    // the provider is `AsyncData` on its first read rather than one microtask
    // of `AsyncLoading` — which is the frame the flash happened in.
    expect(
      _firstFrameTheme(<Override>[
        sharedPreferencesProvider.overrideWith((Ref ref) => prefs),
      ]),
      ThemeMode.dark,
    );
  });

  test('without the override the first frame guesses the device', () async {
    // The old behaviour, kept as the reason the override exists: a seller who
    // chose dark on a light phone saw light first.
    await _prefsWith(<String, Object>{PrefsKeyConstant.themeMode: 'dark'});

    expect(_firstFrameTheme(const <Override>[]), ThemeMode.system);
  });

  test('an unset preference follows the device', () async {
    final SharedPreferences prefs = await _prefsWith(const <String, Object>{});

    expect(
      _firstFrameTheme(<Override>[
        sharedPreferencesProvider.overrideWith((Ref ref) => prefs),
      ]),
      ThemeMode.system,
    );
  });
}
