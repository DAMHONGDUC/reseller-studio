import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../auth/providers.dart';
import '../../../carriers/providers.dart';
import '../../../inventory/providers.dart';
import '../../../marketplaces/providers.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../providers.dart';

/// The workspace creation form.
///
/// **Name, country and currency are the only required fields** (plan §28).
/// The country and currency start from the build's defaults so a seller in
/// the common case taps once and is done.
class WorkspaceSetupState {
  const WorkspaceSetupState({
    this.name = '',
    this.country = AppEnv.defaultCountry,
    this.currency = AppEnv.defaultCurrency,
    this.businessType,
    this.isSaving = false,
  });

  final String name;
  final String country;
  final String currency;
  final String? businessType;
  final bool isSaving;

  bool get canSubmit => name.trim().isNotEmpty && !isSaving;

  WorkspaceSetupState copyWith({
    String? name,
    String? country,
    String? currency,
    String? businessType,
    bool? isSaving,
  }) => WorkspaceSetupState(
    name: name ?? this.name,
    country: country ?? this.country,
    currency: currency ?? this.currency,
    businessType: businessType ?? this.businessType,
    isSaving: isSaving ?? this.isSaving,
  );
}

/// Creating the first workspace — the last step of onboarding (plan §26).
///
/// Nothing below this point in the app is reachable without one: every
/// business record lives under a workspace (hard rule 14), so a signed-in
/// user with none has nowhere to read or write.
class WorkspaceSetupController extends Notifier<WorkspaceSetupState> {
  @override
  WorkspaceSetupState build() => const WorkspaceSetupState();

  void updateName(String value) => state = state.copyWith(name: value);

  void selectCountry(String code) => state = state.copyWith(country: code);

  void selectCurrency(String code) => state = state.copyWith(currency: code);

  void selectBusinessType(String value) =>
      state = state.copyWith(businessType: value);

  /// Writes the workspace and returns its id, or null when the form is not
  /// ready.
  ///
  /// The router is watching `workspaceStatusProvider` and moves the seller to
  /// Home once the profile's pointer lands, so this navigates nowhere itself.
  Future<String?> submit() async {
    final String name = state.name.trim();
    final String? uid = ref.read(currentUidProvider);
    final WorkspaceRepository repository = ref.read(
      workspaceRepositoryProvider,
    );

    if (name.isEmpty || state.isSaving) return null;

    if (uid == null) {
      SdLogger.error(
        LogTagConstant.workspace,
        'Workspace setup submitted with nobody signed in',
        error: StateError('No uid at workspace creation'),
      );

      return null;
    }

    state = state.copyWith(isSaving: true);
    SdLogger.action(
      LogTagConstant.workspace,
      'Workspace setup submitted',
      <String, Object>{
        'country': state.country,
        'currency': state.currency,
        'hasBusinessType': state.businessType != null,
      },
    );

    try {
      final String id = await repository.createWorkspace(
        name: name,
        country: state.country,
        currency: state.currency,
        ownerId: uid,
        ownerName: ref.read(authUserProvider).value?.displayName,
        ownerEmail: ref.read(authUserProvider).value?.email,
        businessType: state.businessType,
        marketplaces: ref.read(defaultMarketplacesProvider),
        categories: ref.read(defaultItemCategoriesProvider),
        carriers: ref.read(defaultCarriersProvider),
      );

      AppAnalytics.instance.workspaceCreated(
        currency: state.currency,
        country: state.country,
      );

      state = state.copyWith(isSaving: false);

      return id;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.workspace,
        'Workspace creation failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'currency': state.currency},
      );

      state = state.copyWith(isSaving: false);

      rethrow;
    }
  }
}

final NotifierProvider<WorkspaceSetupController, WorkspaceSetupState>
workspaceSetupControllerProvider =
    NotifierProvider<WorkspaceSetupController, WorkspaceSetupState>(
      WorkspaceSetupController.new,
    );
