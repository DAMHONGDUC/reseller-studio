import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/logging/firebase_crash_reporter.dart';

/// Sends a test report to Crashlytics from the dev rows on More.
///
/// **Developer-only.** It proves the whole path — SDK, project, upload — on
/// demand, instead of waiting for a real failure to find out nothing arrives.
/// State is just "is it running", so the row can show a spinner.
class CrashlyticsTestController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Returns false when this build has no Crashlytics attached to send to.
  Future<bool> send() async {
    final FirebaseCrashReporter? reporter = FirebaseCrashReporter.attached;

    SdLogger.action(
      LogTagConstant.crashReporting,
      'Send test report',
      <String, bool>{'attached': reporter != null},
    );

    if (reporter == null) return false;

    state = true;

    try {
      await reporter.sendTestReport();

      SdLogger.info(LogTagConstant.crashReporting, 'Test report sent');

      return true;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.crashReporting,
        'Test report failed',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<CrashlyticsTestController, bool>
crashlyticsTestControllerProvider =
    NotifierProvider<CrashlyticsTestController, bool>(
      CrashlyticsTestController.new,
    );
