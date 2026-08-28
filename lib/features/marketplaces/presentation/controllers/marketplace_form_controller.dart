import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../mock_data/providers.dart';
import '../../domain/entities/marketplace.dart';
import '../../marketplace_constant.dart';

/// What the add/edit marketplace form has collected.
class MarketplaceFormState {
  const MarketplaceFormState({this.feeRate, this.isSaving = false});

  /// A fraction of the sale, not a percentage — the field converts, so the
  /// stored number and the typed one never disagree about the factor of 100.
  final double? feeRate;

  final bool isSaving;

  bool get canSubmit =>
      !isSaving &&
      feeRate != null &&
      MarketplaceConstant.isValidFeeRate(feeRate!);

  MarketplaceFormState copyWith({double? feeRate, bool? isSaving}) =>
      MarketplaceFormState(
        feeRate: feeRate ?? this.feeRate,
        isSaving: isSaving ?? this.isSaving,
      );
}

/// Add, rename, reprice and delete a marketplace.
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
      state = MarketplaceFormState(feeRate: marketplace.feeRate);

  /// Resets for a create, because the provider outlives one visit to the form.
  void startCreate() => state = const MarketplaceFormState();

  void updateFeeRate(double? rate) =>
      state = MarketplaceFormState(feeRate: rate, isSaving: state.isSaving);

  /// Returns the id written, or null when the name was empty.
  Future<String?> submit({required String name, String? marketplaceId}) async {
    final String trimmed = name.trim();
    final String id = marketplaceId ?? _uuid.v4();

    final double? feeRate = state.feeRate;

    if (trimmed.isEmpty ||
        state.isSaving ||
        feeRate == null ||
        !MarketplaceConstant.isValidFeeRate(feeRate)) {
      return null;
    }

    state = state.copyWith(isSaving: true);
    SdLogger.action(
      LogTagConstant.marketplace,
      'Marketplace form submitted',
      <String, Object>{
        'marketplaceId': id,
        'isEditing': marketplaceId != null,
        'feePercent': feeRate * 100,
      },
    );

    try {
      // Read fresh rather than held from when the screen opened: only the two
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
                    feeRate: feeRate,
                    createdAt: DateTime.now(),
                  )
                : current.copyWith(name: trimmed, feeRate: feeRate),
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
