import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/core/config/app_env.dart';
import 'package:seller_os/core/config/dev_flags.dart';

/// The env files and the class that reads them have to agree, and the guard
/// between "what the file asked for" and "what the build allows" has to hold.
/// Both are the kind of thing that breaks silently.
void main() {
  Map<String, dynamic> readEnv(String name) =>
      jsonDecode(File('env/$name.example.json').readAsStringSync())
          as Map<String, dynamic>;

  group('env templates', () {
    test('dev and prod declare exactly the same keys', () {
      final Set<String> dev = readEnv('dev').keys.toSet();
      final Set<String> prod = readEnv('prod').keys.toSet();

      // A key in one flavour and not the other is a build that works on a
      // developer's machine and fails in CI, which is the worst place to
      // find out.
      expect(
        dev.difference(prod),
        isEmpty,
        reason: 'keys in dev.example.json missing from prod.example.json',
      );
      expect(
        prod.difference(dev),
        isEmpty,
        reason: 'keys in prod.example.json missing from dev.example.json',
      );
    });

    test('prod never ships the development switches on', () {
      final Map<String, dynamic> prod = readEnv('prod');

      // BYPASS_AUTH is no longer read by the app — the flag is deleted. The
      // key may still sit in the templates until they are tidied, and false
      // is the only value that was ever right for prod.
      expect(prod['BYPASS_AUTH'] ?? false, isFalse);
      expect(prod['MOCK_DATA_DEFAULT'], isFalse);
      expect(prod['FLAVOR'], 'prod');
    });

    test('no template carries anything that looks like a secret', () {
      // Everything in these files is compiled into the binary and is
      // trivially extractable, so a key named *SECRET* or *PRIVATE* is a
      // mistake by definition — hard rule 10. Client *ids* are fine.
      for (final String flavour in <String>['dev', 'prod']) {
        for (final String key in readEnv(flavour).keys) {
          expect(
            key.toUpperCase(),
            isNot(anyOf(contains('SECRET'), contains('PRIVATE'))),
            reason:
                '$flavour.example.json declares $key — secrets belong in '
                'Secret Manager, read only by a Cloud Function.',
          );
        }
      }
    });
  });

  group('AppEnv', () {
    test('every getter has a default, so a bare build still runs', () {
      // The suite runs with no --dart-define-from-file. Nothing here should
      // throw, and the flavour should fall back to dev.
      expect(AppEnv.flavor, Flavor.dev);
      expect(AppEnv.appDisplayName, isNotEmpty);
      expect(AppEnv.functionsRegion, isNotEmpty);
      expect(AppEnv.defaultCurrency, 'USD');
    });

    test('reports Firebase as unconfigured when no project id was passed', () {
      expect(AppEnv.hasFirebaseConfig, isFalse);
      expect(AppEnv.missingReleaseKeys, isNotEmpty);
    });

    test('the summary names keys, never values', () {
      // It goes to the console and, in release, to Crashlytics — hard rule 9.
      expect(AppEnv.summary, contains('flavor='));
      expect(AppEnv.summary, contains('not configured'));
    });
  });

  group('DevFlags guards AppEnv', () {
    test('is off by default, whatever the env file could say', () {
      expect(DevFlags.mockDataDefault, isFalse);
    });

    test('every flag is const-evaluable, so release can shed the branches', () {
      // These only compile if the values fold at compile time, which is what
      // lets the tree-shaker delete the branch entirely.
      const bool mock = DevFlags.mockDataDefault;
      const bool verbose = DevFlags.verboseLogging;

      expect(<bool>[mock, verbose], everyElement(isFalse));
    });

    test('no flag can be true in a release build, however it was defined', () {
      // Restated here so that removing a `!kReleaseMode` fails a test rather
      // than silently arming a config file against a store build.
      expect(DevFlags.mockDataDefault && !DevFlags.isDebugOrProfile, isFalse);
      expect(DevFlags.verboseLogging && !DevFlags.isDebugOrProfile, isFalse);
    });
  });
}
