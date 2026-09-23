import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:reseller_studio/reseller_studio_app.dart';

/// What a build offers a device, and that every offered locale is complete.
///
/// The generator fills a missing key from English without failing, so a gap
/// ships as a mixed-language screen — hard rule 7 is what this pins.
void main() {
  const String arbDirectory = 'lib/l10n';
  final RegExp placeholder = RegExp(r'\{(\w+)[},]');

  Map<String, String> messages(String locale) {
    final Map<String, dynamic> arb =
        jsonDecode(File('$arbDirectory/app_$locale.arb').readAsStringSync())
            as Map<String, dynamic>;

    return <String, String>{
      for (final MapEntry<String, dynamic> entry in arb.entries)
        if (!entry.key.startsWith('@')) entry.key: entry.value as String,
    };
  }

  // Names at brace depth zero only: an ICU branch like `other{Save}` is
  // translated text, not a placeholder.
  Set<String> placeholders(String message) {
    final Set<String> names = <String>{};
    int depth = 0;

    for (int index = 0; index < message.length; index++) {
      if (message[index] == '{') {
        if (depth == 0) {
          names.add(placeholder.matchAsPrefix(message, index)!.group(1)!);
        }
        depth++;
      } else if (message[index] == '}') {
        depth--;
      }
    }

    return names;
  }

  test('the seven locales ship, English first', () {
    expect(ResellerStudioApp.shippingLocales, const <Locale>[
      Locale('en'),
      Locale('es'),
      Locale('fr'),
      Locale('de'),
      Locale('pt'),
      Locale('zh'),
      Locale('vi'),
    ]);
  });

  test('every shipping locale is generated', () {
    for (final Locale locale in ResellerStudioApp.shippingLocales) {
      expect(AppLocalizations.supportedLocales, contains(locale));
    }
  });

  test('iOS declares every shipping locale', () {
    final String plist = File('ios/Runner/Info.plist').readAsStringSync();
    const Map<String, String> iosCode = <String, String>{'zh': 'zh-Hans'};

    for (final Locale locale in ResellerStudioApp.shippingLocales) {
      final String code = iosCode[locale.languageCode] ?? locale.languageCode;

      expect(plist, contains('<string>$code</string>'), reason: code);
    }
  });

  test('every ARB has exactly the template keys and placeholders', () {
    final Map<String, String> template = messages('en');

    for (final Locale locale in ResellerStudioApp.shippingLocales) {
      final Map<String, String> translated = messages(locale.languageCode);

      expect(
        translated.keys.toSet(),
        template.keys.toSet(),
        reason: locale.languageCode,
      );
      for (final MapEntry<String, String> entry in template.entries) {
        expect(
          placeholders(translated[entry.key]!),
          placeholders(entry.value),
          reason: '${locale.languageCode}.${entry.key}',
        );
      }
    }
  });
}
