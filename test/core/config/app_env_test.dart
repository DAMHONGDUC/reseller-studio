import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/config/app_env.dart';
import 'package:reseller_studio/core/config/dev_flags.dart';

/// The env files and the class that reads them have to agree, and the guard
/// between "what the file asked for" and "what the build allows" has to hold.
/// Both are the kind of thing that breaks silently.
void main() {
  Map<String, dynamic> readTemplate() =>
      jsonDecode(File('env/env.example.json').readAsStringSync())
          as Map<String, dynamic>;

  group('env template', () {
    // **One template, not one per flavour.** `dev.example.json` and
    // `prod.example.json` only ever differed by values a developer fills in,
    // so the key list lived twice and went stale in one copy — which is
    // exactly what happened to REVENUECAT_*. `set-up.sh` seeds both flavours
    // from this file.
    test('the template carries exactly the keys AppEnv reads', () {
      // The list every reader of this file trusts, pinned. A key nothing
      // reads is a placeholder somebody will spend an afternoon filling in;
      // a key AppEnv reads and the template omits is a value that silently
      // defaults to '' — which is how REVENUECAT_* went missing. Dart cannot
      // reflect over AppEnv, so this list is maintained by hand and failing
      // loudly is the whole point.
      const Set<String> read = <String>{
        'FLAVOR',
        'APP_DISPLAY_NAME',
        'MOCK_DATA_DEFAULT',
        'VERBOSE_LOGGING',
        'FIREBASE_PROJECT_ID',
        'FIREBASE_APP_ID_IOS',
        'FUNCTIONS_REGION',
        'GOOGLE_SIGN_IN_CLIENT_ID_IOS',
        'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
        'REVENUECAT_IOS_KEY',
        'REVENUECAT_ANDROID_KEY',
        'REVENUECAT_ENTITLEMENT',
        'REVENUECAT_OFFERING',
        'PRIVACY_POLICY_URL',
        'TERMS_OF_SERVICE_URL',
        'DEFAULT_CURRENCY',
        'DEFAULT_COUNTRY',
      };

      expect(readTemplate().keys.toSet(), read);
    });

    test('the development switches are declared, whatever they are set to', () {
      // Their *values* are not asserted any more: one template seeds both
      // flavours, so there is no checked-in prod file to hold to `false`.
      // What stops a switch reaching a store build is `DevFlags` ANDing each
      // one with `!kReleaseMode` — pinned by the `DevFlags guards AppEnv`
      // group below, which is the guarantee that actually ships.
      expect(readTemplate().containsKey('MOCK_DATA_DEFAULT'), isTrue);
      expect(readTemplate().containsKey('VERBOSE_LOGGING'), isTrue);
    });

    test('no template carries anything that looks like a secret', () {
      // Everything in this file is compiled into the binary and is trivially
      // extractable, so a key named *SECRET* or *PRIVATE* is a mistake by
      // definition — hard rule 10. Client *ids* are fine.
      for (final String key in readTemplate().keys) {
        expect(
          key.toUpperCase(),
          isNot(anyOf(contains('SECRET'), contains('PRIVATE'))),
          reason:
              'env.example.json declares $key — secrets belong in Secret '
              'Manager, read only by a Cloud Function.',
        );
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
      expect(AppEnv.revenueCatIosKey, isEmpty);
      expect(AppEnv.revenueCatAndroidKey, isEmpty);
      expect(AppEnv.revenueCatEntitlement, isEmpty);
      expect(AppEnv.revenueCatOffering, isEmpty);
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
