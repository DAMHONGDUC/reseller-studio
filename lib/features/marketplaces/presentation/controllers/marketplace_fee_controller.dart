import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../workspace/domain/entities/workspace.dart';
import '../../../workspace/providers.dart';
import '../../domain/enums/marketplace.dart';

/// Correcting what a platform actually charges this business.
///
/// **The rate lives on the workspace, not on the enum** — the enum's number is
/// the platform's published headline, and a seller on a shop tier, in another
/// country, or with a category discount pays something else. Only the
/// corrections are stored; see `MarketplaceFeePolicy`.
///
/// **The workspace is re-read at the moment of the write**, never held from
/// when the screen opened: a teammate renaming the business in between would
/// otherwise be undone by a stale copy. The same rule the detail form follows.
class MarketplaceFeeController extends Notifier<bool> {
  /// True while a write is in flight, so a row can disable itself.
  @override
  bool build() => false;

  /// Set [marketplace]'s rate for this business, or null to go back to the
  /// platform's published one.
  Future<void> setRate(Marketplace marketplace, double? rate) async {
    final Workspace? workspace = ref.read(currentWorkspaceProvider);

    if (workspace == null) return;

    final Map<String, double> next = <String, double>{
      ...workspace.marketplaceFeeRates,
    };

    if (rate == null) {
      next.remove(marketplace.name);
    } else {
      next[marketplace.name] = rate;
    }

    SdLogger.action(
      LogTagConstant.marketplace,
      'Set marketplace fee',
      <String, Object>{
        'marketplace': marketplace.name,
        'ratePercent': rate == null ? 'default' : rate * 100,
        'workspaceId': workspace.id,
      },
    );

    state = true;

    try {
      await ref
          .read(workspaceRepositoryProvider)
          .updateWorkspace(workspace.copyWith(marketplaceFeeRates: next));

      SdLogger.info(
        LogTagConstant.marketplace,
        'Marketplace fee saved',
        <String, Object>{'marketplace': marketplace.name},
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.marketplace,
        'Failed to save marketplace fee',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{
          'marketplace': marketplace.name,
          'workspaceId': workspace.id,
        },
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<MarketplaceFeeController, bool>
marketplaceFeeControllerProvider =
    NotifierProvider<MarketplaceFeeController, bool>(
      MarketplaceFeeController.new,
    );
