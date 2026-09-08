import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/constants/prefs_key_constant.dart';
import 'package:reseller_studio/core/providers/shared_preferences_provider.dart';
import 'package:reseller_studio/features/onboarding/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/pump_app.dart';

/// The one bit the intro flow owns: whether it has been got through on this
/// install (hard rule 1).
///
/// **Loading is not "not seen".** Preferences are unresolved for the first
/// frame of every cold start, so defaulting to `pending` would flash the
/// intro at a seller who has been using the app for months — which is the
/// same mistake as flashing the login screen at a signed-in one.
///
/// **Skipping counts as finishing.** Somebody who does not want the tour is
/// not asked again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> withPrefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);

    final ProviderContainer container = mockContainer();

    await container.read(sharedPreferencesProvider.future);

    return container;
  }

  test('a fresh install has the intro still to run', () async {
    final ProviderContainer container = await withPrefs(<String, Object>{});

    expect(container.read(onboardingStatusProvider), OnboardingStatus.pending);
  });

  test('an install that has seen it does not see it again', () async {
    final ProviderContainer container = await withPrefs(<String, Object>{
      PrefsKeyConstant.onboardingSeen: true,
    });

    expect(container.read(onboardingStatusProvider), OnboardingStatus.done);
  });

  test('the status is loading until preferences resolve', () {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final ProviderContainer container = mockContainer();

    // Read before the await: this is the first frame of a cold start, and
    // the router shows the splash for it rather than the intro.
    expect(container.read(onboardingStatusProvider), OnboardingStatus.loading);
  });

  test('finishing is remembered, and skipping is finishing', () async {
    final ProviderContainer container = await withPrefs(<String, Object>{});

    await container.read(onboardingStatusProvider.notifier).complete();

    expect(container.read(onboardingStatusProvider), OnboardingStatus.done);

    // Written through, so the next launch reads it back.
    expect(
      container
          .read(sharedPreferencesProvider)
          .value!
          .getBool(PrefsKeyConstant.onboardingSeen),
      isTrue,
    );
  });

  test('the state moves on the tap, not after the disk write', () async {
    final ProviderContainer container = await withPrefs(<String, Object>{});
    final Future<void> pending = container
        .read(onboardingStatusProvider.notifier)
        .complete();

    // The router advances immediately; a failed write costs one more sight
    // of the intro, which beats a button that looks dead.
    expect(container.read(onboardingStatusProvider), OnboardingStatus.done);

    await pending;
  });
}
