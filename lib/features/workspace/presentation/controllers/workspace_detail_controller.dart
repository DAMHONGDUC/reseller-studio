import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/workspace.dart';
import '../../providers.dart';

/// The business detail form's draft.
///
/// **It carries the workspace id it is editing.** The switcher can open the
/// screen on a business the seller is not currently standing in, so a
/// controller that read `currentWorkspaceProvider` would silently write to the
/// wrong record.
class WorkspaceDetailState {
  const WorkspaceDetailState({
    this.workspaceId,
    this.name = '',
    this.country = '',
    this.currency = '',
    this.businessType,
    this.staleThresholdDays = 0,
    this.lowStockThreshold = 0,
    this.isSaving = false,
  });

  final String? workspaceId;
  final String name;
  final String country;
  final String currency;
  final String? businessType;
  final int staleThresholdDays;
  final int lowStockThreshold;
  final bool isSaving;

  /// A business always has a name (plan §28), so an emptied field is the one
  /// thing this form refuses.
  bool get canSubmit =>
      workspaceId != null && name.trim().isNotEmpty && !isSaving;

  WorkspaceDetailState copyWith({
    String? workspaceId,
    String? name,
    String? country,
    String? currency,
    String? businessType,
    int? staleThresholdDays,
    int? lowStockThreshold,
    bool? isSaving,
  }) => WorkspaceDetailState(
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    country: country ?? this.country,
    currency: currency ?? this.currency,
    businessType: businessType ?? this.businessType,
    staleThresholdDays: staleThresholdDays ?? this.staleThresholdDays,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    isSaving: isSaving ?? this.isSaving,
  );
}

/// Changing the business itself — its name, where it files, what it counts in
/// (plan §25's Workspace block), and ending it.
///
/// **`updateWorkspace` existed and nothing called it**, so a country picked
/// wrongly at setup was permanent — and the country is what decides the tax
/// jurisdiction, the tax year boundary and the mileage rate. That is the bug
/// this controller closes.
///
/// **One draft and one write, not a write per row.** Settings used to open a
/// picker per field and save on the tap; the screen this drives is a form with
/// a pinned save (owner's rule), so correcting the country and the currency
/// together is one write rather than two.
class WorkspaceDetailController extends Notifier<WorkspaceDetailState> {
  @override
  WorkspaceDetailState build() => const WorkspaceDetailState();

  /// Fills the draft from the record. The screen calls it once — the provider
  /// outlives one visit, so a second business opened after a first would
  /// otherwise inherit its country.
  void seed(Workspace workspace) {
    state = WorkspaceDetailState(
      workspaceId: workspace.id,
      name: workspace.name,
      country: workspace.country,
      currency: workspace.currency,
      businessType: workspace.businessType,
      staleThresholdDays: workspace.staleThresholdDays,
      lowStockThreshold: workspace.lowStockThreshold,
    );
  }

  void updateName(String value) => state = state.copyWith(name: value);

  void selectCountry(String code) => state = state.copyWith(country: code);

  /// **Does not convert a single stored amount, and must never try** — nobody
  /// knows what rate applied to a purchase made last March. It changes what
  /// new money fields default to.
  void selectCurrency(String code) => state = state.copyWith(currency: code);

  void selectBusinessType(String key) =>
      state = state.copyWith(businessType: key);

  void selectStaleThresholdDays(int days) =>
      state = state.copyWith(staleThresholdDays: days);

  /// How few items on hand before the daily digest says so.
  ///
  /// **Read by a Cloud Function, not by a screen** — the reminder is sent from
  /// the backend, so this setting is the only thing the app contributes to it.
  void selectLowStockThreshold(int items) =>
      state = state.copyWith(lowStockThreshold: items);

  /// Writes the draft over the record, and answers whether it went.
  ///
  /// **The workspace is re-read here rather than held from when the screen
  /// opened**: a teammate renaming the business in between would otherwise be
  /// undone by a stale copy. Only the fields this form owns are applied.
  Future<bool> submit() async {
    final WorkspaceDetailState draft = state;
    final String? id = draft.workspaceId;

    if (!draft.canSubmit || id == null) return false;

    final Workspace? current = ref.read(liveWorkspaceProvider(id)).value;

    if (current == null) return false;

    state = state.copyWith(isSaving: true);
    SdLogger.action(
      LogTagConstant.workspace,
      'Save workspace',
      <String, Object>{
        'workspaceId': id,
        'country': draft.country,
        'currency': draft.currency,
        'staleThresholdDays': draft.staleThresholdDays,
        'lowStockThreshold': draft.lowStockThreshold,
      },
    );

    try {
      await ref
          .read(workspaceRepositoryProvider)
          .updateWorkspace(
            current.copyWith(
              name: draft.name.trim(),
              country: draft.country,
              currency: draft.currency,
              businessType: draft.businessType,
              staleThresholdDays: draft.staleThresholdDays,
              lowStockThreshold: draft.lowStockThreshold,
            ),
          );

      state = state.copyWith(isSaving: false);

      return true;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.workspace,
        'Failed to save workspace',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'workspaceId': id},
      );

      state = state.copyWith(isSaving: false);

      rethrow;
    }
  }

  /// End the business: its records, its files and the invitations to it.
  ///
  /// **Not part of [submit]** — that reads the workspace and writes it back,
  /// and there is nothing to write back here. The call is a Cloud Function
  /// (`workspaces/{id}` is `allow delete: if false`), and the owner check is
  /// the function's, not this one's.
  ///
  /// Nothing navigates afterwards. The membership goes with the business, the
  /// profile stream drops the id, and the router's own redirect decides where
  /// the seller lands — Home on the business they still have, workspace setup
  /// when that was the last one.
  Future<void> delete(String workspaceId) async {
    state = state.copyWith(isSaving: true);
    SdLogger.action(
      LogTagConstant.workspace,
      'Delete workspace',
      <String, Object>{'workspaceId': workspaceId},
    );

    try {
      await ref.read(workspaceRepositoryProvider).deleteWorkspace(workspaceId);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.workspace,
        'Failed to delete workspace',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'workspaceId': workspaceId},
      );

      rethrow;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final NotifierProvider<WorkspaceDetailController, WorkspaceDetailState>
workspaceDetailControllerProvider =
    NotifierProvider<WorkspaceDetailController, WorkspaceDetailState>(
      WorkspaceDetailController.new,
    );
