import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/money/money.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../mock_data/providers.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/source.dart';

/// Creating and editing sources and purchases — the first two links of the
/// chain the whole product is built on.
///
/// `Source → Purchase → Item` is what makes "which source performs best"
/// answerable, and the reason the Sourcing feature exists at all: without it
/// the app can say what sold and not where to find more of it.
class SourcingController extends Notifier<bool> {
  static const Uuid _uuid = Uuid();

  /// True while a write is in flight.
  @override
  bool build() => false;

  /// **Only the name is required** (plan §28). A seller adding a source
  /// mid-hunt types the shop name and moves on; the address and phone are for
  /// the ones worth going back to.
  Future<String?> saveSource({
    required String name,
    String? id,
    SourceType? type,
    String? address,
    String? phone,
    String? website,
    String? notes,
  }) async {
    final String trimmed = name.trim();
    final String sourceId = id ?? _uuid.v4();

    if (trimmed.isEmpty) return null;

    state = true;
    AppLogger.action('Save source', <String, Object>{
      'sourceId': sourceId,
      'isNew': id == null,
      'hasType': type != null,
    });

    try {
      await ref
          .read(sourceRepositoryProvider)
          .save(
            Source(
              id: sourceId,
              name: trimmed,
              createdAt: DateTime.now(),
              type: type,
              address: _orNull(address),
              phone: _orNull(phone),
              website: _orNull(website),
              notes: _orNull(notes),
            ),
          );

      return sourceId;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save source',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'sourceId': sourceId},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> deleteSource(String id) async {
    state = true;
    AppLogger.action('Delete source', <String, Object>{'sourceId': id});

    try {
      await ref.read(sourceRepositoryProvider).delete(id);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete source',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'sourceId': id},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// A buying trip. **The date is required** (plan §28) — a purchase with no
  /// date cannot be placed in any report, and every tax summary is built by
  /// period.
  ///
  /// The total is what left the seller's pocket, from the receipt. It is
  /// deliberately not derived from the item costs: a $40 box lot apportioned
  /// across eleven items legitimately does not sum to $40.
  Future<String?> savePurchase({
    required DateTime purchaseDate,
    String? id,
    String? sourceId,
    String totalCost = '',
    String? notes,
    int itemCount = 0,
  }) async {
    final String purchaseId = id ?? _uuid.v4();
    final String currency = ref.read(workspaceCurrencyProvider);

    state = true;
    AppLogger.action('Save purchase', <String, Object>{
      'purchaseId': purchaseId,
      'isNew': id == null,
      'hasSource': sourceId != null,
    });

    try {
      await ref
          .read(purchaseRepositoryProvider)
          .save(
            Purchase(
              id: purchaseId,
              purchaseDate: purchaseDate,
              createdAt: DateTime.now(),
              sourceId: sourceId,
              totalCost: Money.tryParse(totalCost, currency),
              notes: _orNull(notes),
              itemCount: itemCount,
            ),
          );

      return purchaseId;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save purchase',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'purchaseId': purchaseId},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> deletePurchase(String id) async {
    state = true;
    AppLogger.action('Delete purchase', <String, Object>{'purchaseId': id});

    try {
      await ref.read(purchaseRepositoryProvider).delete(id);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete purchase',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'purchaseId': id},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// An empty box means "not entered", which is a null field rather than an
  /// empty string.
  static String? _orNull(String? value) {
    final String trimmed = value?.trim() ?? '';

    return trimmed.isEmpty ? null : trimmed;
  }
}

final NotifierProvider<SourcingController, bool> sourcingControllerProvider =
    NotifierProvider<SourcingController, bool>(SourcingController.new);
