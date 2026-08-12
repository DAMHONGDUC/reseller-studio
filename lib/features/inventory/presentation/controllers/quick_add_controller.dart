import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../mock_data/providers.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';
import '../../domain/repositories/item_repository.dart';

/// What Quick Add is doing right now.
///
/// [title] is the only field, because **create takes the minimum** (hard rule
/// 2). Everything else about an item attaches when it moves — see
/// `ItemTransition`.
class QuickAddState {
  const QuickAddState({
    this.title = '',
    this.isSaving = false,
    this.savedItemId,
  });

  final String title;
  final bool isSaving;

  /// Set once the write lands, so the screen knows to leave. Null while the
  /// form is still open.
  final String? savedItemId;

  /// A title with something in it is the whole of the validation.
  bool get canSubmit => title.trim().isNotEmpty && !isSaving;

  QuickAddState copyWith({String? title, bool? isSaving, String? savedItemId}) =>
      QuickAddState(
        title: title ?? this.title,
        isSaving: isSaving ?? this.isSaving,
        savedItemId: savedItemId ?? this.savedItemId,
      );
}

/// Creating an item from a title alone.
///
/// **The fast path the whole product's speed rests on** (hard rule 2, plan
/// §28). A seller standing in a thrift store types a title and is done; a
/// price, a photo, a category and a source are all things they may add later
/// or never. Any new required field here needs explicit approval.
///
/// The item lands as [ItemStatus.draft] — created, not yet sellable inventory.
class QuickAddController extends Notifier<QuickAddState> {
  static const Uuid _uuid = Uuid();

  @override
  QuickAddState build() => const QuickAddState();

  void updateTitle(String value) =>
      state = state.copyWith(title: value, savedItemId: null);

  /// Writes the item and returns its id, or null when the form is not ready.
  ///
  /// Logs on the way in and on the way out, with the data both times — a line
  /// saying "Quick Add submitted" that does not say what was submitted cannot
  /// answer anything later.
  Future<String?> submit() async {
    final String title = state.title.trim();
    final String id = _uuid.v4();
    final ItemRepository repository = ref.read(itemRepositoryProvider);

    if (title.isEmpty || state.isSaving) return null;

    state = state.copyWith(isSaving: true);
    AppLogger.action('Quick Add submitted', <String, Object>{
      'itemId': id,
      'titleLength': title.length,
    });

    try {
      final Item item = Item(
        id: id,
        title: title,
        quantity: 1,
        status: ItemStatus.draft,
        createdAt: DateTime.now(),
      );

      await repository.save(item);

      AppLogger.info('Quick Add saved', <String, Object>{
        'itemId': id,
        'status': ItemStatus.draft.name,
      });
      AppAnalytics.instance.itemCreated(viaQuickAdd: true, hasPhoto: false);

      state = state.copyWith(isSaving: false, savedItemId: id);

      return id;
    } catch (error, stackTrace) {
      // Logged here and rethrown: the log is an extra pair of eyes, never a
      // replacement for the caller's error handling.
      AppLogger.error(
        'Quick Add failed to save',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'itemId': id, 'titleLength': title.length},
      );

      state = state.copyWith(isSaving: false);

      rethrow;
    }
  }
}

final NotifierProvider<QuickAddController, QuickAddState>
quickAddControllerProvider =
    NotifierProvider<QuickAddController, QuickAddState>(QuickAddController.new);
