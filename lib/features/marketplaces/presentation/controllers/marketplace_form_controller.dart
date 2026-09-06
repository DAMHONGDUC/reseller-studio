import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_tag_hue.dart';
import '../../domain/entities/marketplace.dart';

/// What the add/edit marketplace form has collected.
class MarketplaceFormState {
  const MarketplaceFormState({
    this.hue = AppTagHue.grey,
    this.isSaving = false,
  });

  /// The colour every row naming this marketplace will wear. Never null — a
  /// new record starts on grey rather than on "not chosen".
  final AppTagHue hue;

  final bool isSaving;

  bool get canSubmit => !isSaving;

  MarketplaceFormState copyWith({AppTagHue? hue, bool? isSaving}) =>
      MarketplaceFormState(
        hue: hue ?? this.hue,
        isSaving: isSaving ?? this.isSaving,
      );
}

/// Add, rename, recolour and delete a marketplace.
///
/// **There is no rate to collect** (hard rule 3): what a platform charges is
/// measured from each order's payout, so this form owns a name and a colour.
///
/// **The name stays in the screen's `TextEditingController`** and arrives as
/// an argument to [submit], the way the item form does it: holding it here
/// would rebuild the form on every keystroke.
class MarketplaceFormController extends Notifier<MarketplaceFormState> {
  static const Uuid _uuid = Uuid();

  @override
  MarketplaceFormState build() => const MarketplaceFormState();

  /// Loads an existing marketplace into the form. Called once — see
  /// `FormSeed`.
  void seed(Marketplace marketplace) =>
      state = MarketplaceFormState(hue: marketplace.hue);

  /// Resets for a create, because the provider outlives one visit to the form.
  void startCreate() => state = const MarketplaceFormState();

  void selectHue(AppTagHue hue) => state = state.copyWith(hue: hue);

  /// Returns the id written, or null when the name was empty.
  Future<String?> submit({required String name, String? marketplaceId}) async {
    final String trimmed = name.trim();
    final String id = marketplaceId ?? _uuid.v4();

    final AppTagHue hue = state.hue;

    if (trimmed.isEmpty || state.isSaving) {
      return null;
    }

    state = state.copyWith(isSaving: true);
    SdLogger.action(
      LogTagConstant.marketplace,
      'Marketplace form submitted',
      <String, Object>{
        'marketplaceId': id,
        'isEditing': marketplaceId != null,
        'hue': hue.name,
      },
    );

    try {
      // Read fresh rather than held from when the screen opened: only the
      // fields this form owns are applied, so a teammate's edit survives.
      final List<Marketplace> existing = await ref
          .read(marketplaceRepositoryProvider)
          .watchMarketplaces()
          .first;
      final Marketplace? current = existing
          .where((Marketplace row) => row.id == id)
          .firstOrNull;

      await ref
          .read(marketplaceRepositoryProvider)
          .save(
            current == null
                ? Marketplace(
                    id: id,
                    name: trimmed,
                    createdAt: DateTime.now(),
                    hue: hue,
                  )
                : current.copyWith(name: trimmed, hue: hue),
          );

      return id;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.marketplace,
        'Marketplace form failed to save',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'marketplaceId': id},
      );

      rethrow;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> delete(String marketplaceId) async {
    SdLogger.action(
      LogTagConstant.marketplace,
      'Delete marketplace',
      <String, Object>{'marketplaceId': marketplaceId},
    );

    try {
      await ref.read(marketplaceRepositoryProvider).delete(marketplaceId);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.marketplace,
        'Failed to delete marketplace',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'marketplaceId': marketplaceId},
      );

      rethrow;
    }
  }
}

final NotifierProvider<MarketplaceFormController, MarketplaceFormState>
marketplaceFormControllerProvider =
    NotifierProvider<MarketplaceFormController, MarketplaceFormState>(
      MarketplaceFormController.new,
    );
