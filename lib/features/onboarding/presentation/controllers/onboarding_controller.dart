import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../mock_data/providers.dart';
import '../../onboarding_status.dart';

/// Reads and writes the one bit the intro flow owns: whether it has been got
/// through on this install.
///
/// **[build] returns [OnboardingStatus.loading] until preferences resolve**,
/// and the router shows the splash for that moment. Defaulting to `pending`
/// instead would flash the intro at every returning seller on every cold
/// start, because preferences are always unresolved for the first frame.
class OnboardingController extends Notifier<OnboardingStatus> {
  @override
  OnboardingStatus build() {
    final SharedPreferences? prefs = ref.watch(sharedPreferencesProvider).value;

    if (prefs == null) return OnboardingStatus.loading;

    final bool seen = prefs.getBool(PrefsKeyConstant.onboardingSeen) ?? false;

    return seen ? OnboardingStatus.done : OnboardingStatus.pending;
  }

  /// Marks the intro finished, whether it was read through or skipped.
  ///
  /// **State moves before the write is awaited**, so the router advances on
  /// the tap rather than after a disk round trip. A failed write costs the
  /// seller one more sight of the intro next launch, which is a better
  /// outcome than a button that appears dead.
  ///
  /// **It logs but deliberately does not rethrow**, which is the one place
  /// this departs from the controller rule in `CLAUDE.md`. By the time the
  /// write lands the router has already left this route on the state change
  /// above, so there is no caller left to handle it — rethrowing would only
  /// raise an unhandled async error into a disposed widget.
  Future<void> complete() async {
    state = OnboardingStatus.done;

    final SharedPreferences? prefs = ref.read(sharedPreferencesProvider).value;

    if (prefs == null) {
      SdLogger.warning(
        LogTagConstant.onboarding,
        'Could not persist onboarding — preferences not ready',
      );

      return;
    }

    try {
      await prefs.setBool(PrefsKeyConstant.onboardingSeen, true);
      SdLogger.action(
        LogTagConstant.onboarding,
        'Onboarding completed',
        <String, bool>{'persisted': true},
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.onboarding,
        'Persist onboarding flag failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, String>{'key': PrefsKeyConstant.onboardingSeen},
      );
    }
  }
}
