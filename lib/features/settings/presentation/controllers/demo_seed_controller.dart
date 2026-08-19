import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/time/app_clock.dart';
import '../../../mock_data/domain/mock_dataset.dart';
import '../../../mock_data/domain/services/demo_data_seeder.dart';
import '../../../mock_data/providers.dart';
import '../../../workspace/providers.dart';

/// Writes the demo business into the workspace that is currently open.
///
/// **Developer-only, and it writes for real.** It exists because a brand new
/// account is an empty account: the app has five tabs and nothing to put in
/// them, so the first thing anyone sees of it is five empty states. Seeding is
/// what makes a fresh workspace demonstrable, and it is the only thing that
/// drives every live write path in one run.
///
/// State is just "is it running", so the button can show a spinner. The count
/// comes back from [seed] rather than being held here — the screen shows it
/// once, in a snackbar, and nothing else ever reads it.
class DemoSeedController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Returns how many documents were written.
  Future<int> seed() async {
    final DemoDataSeeder seeder = ref.read(demoDataSeederProvider);
    final DateTime now = ref.read(clockProvider).now();
    final String currency = ref.read(workspaceCurrencyProvider);

    state = true;

    try {
      // The workspace's own currency, not the seed's default: a GBP business
      // filled with dollar amounts is a demo that argues against itself.
      return await seeder.seed(
        MockDataset.seed(now: now, currency: currency),
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.workspace,
        'Demo seed failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, String>{'currency': currency},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<DemoSeedController, bool> demoSeedControllerProvider =
    NotifierProvider<DemoSeedController, bool>(DemoSeedController.new);
