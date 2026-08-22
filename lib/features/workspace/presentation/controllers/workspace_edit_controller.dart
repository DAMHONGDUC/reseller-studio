import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/workspace.dart';
import '../../providers.dart';

/// Changing the business itself — its name, where it files, what it counts in
/// (plan §25's Workspace block).
///
/// **`updateWorkspace` existed and nothing called it**, so a country picked
/// wrongly at setup was permanent — and the country is what decides the tax
/// jurisdiction, the tax year boundary and the mileage rate. That is the bug
/// this controller closes.
///
/// One method per field rather than one `save(Workspace)`: every change here
/// is a single tap on a single row, and a form that collected four of them
/// before writing would make correcting the country a four-field ceremony.
class WorkspaceEditController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> rename(String name) {
    final String trimmed = name.trim();

    if (trimmed.isEmpty) return Future<void>.value();

    return _apply('rename', <String, Object>{}, (Workspace current) {
      return current.copyWith(name: trimmed);
    });
  }

  /// **Does not convert a single stored amount, and must never try** — nobody
  /// knows what rate applied to a purchase made last March. It changes what
  /// new money fields default to.
  Future<void> setCurrency(String code) =>
      _apply('set currency', <String, Object>{'currency': code}, (
        Workspace current,
      ) {
        return current.copyWith(currency: code);
      });

  /// The tax jurisdiction follows from this, so it is the one field here that
  /// changes what a number *means* rather than how it is shown.
  Future<void> setCountry(String code) =>
      _apply('set country', <String, Object>{'country': code}, (
        Workspace current,
      ) {
        return current.copyWith(country: code);
      });

  Future<void> setBusinessType(String key) =>
      _apply('set business type', <String, Object>{'businessType': key}, (
        Workspace current,
      ) {
        return current.copyWith(businessType: key);
      });

  Future<void> setStaleThresholdDays(int days) =>
      _apply('set stale threshold', <String, Object>{'days': days}, (
        Workspace current,
      ) {
        return current.copyWith(staleThresholdDays: days);
      });

  /// Reads the workspace, applies [change], writes it back.
  ///
  /// Read at the moment of the write rather than held in state: a teammate
  /// renaming the business between the screen opening and this tap would
  /// otherwise be undone by a stale copy.
  Future<void> _apply(
    String what,
    Map<String, Object> data,
    Workspace Function(Workspace current) change,
  ) async {
    final Workspace? current = ref.read(currentWorkspaceProvider);

    if (current == null) return;

    state = true;
    SdLogger.action(LogTagConstant.workspace, 'Workspace $what', <String, Object>{
      'workspaceId': current.id,
      ...data,
    });

    try {
      await ref.read(workspaceRepositoryProvider).updateWorkspace(
        change(current),
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.workspace,
        'Failed to $what',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'workspaceId': current.id, ...data},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<WorkspaceEditController, bool>
workspaceEditControllerProvider =
    NotifierProvider<WorkspaceEditController, bool>(
      WorkspaceEditController.new,
    );
