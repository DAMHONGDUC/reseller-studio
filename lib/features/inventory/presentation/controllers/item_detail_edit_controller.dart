import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/text_input_utils.dart';
import '../../../mock_data/providers.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';
import '../../domain/services/item_transition.dart';

/// Which block of the item detail screen is open for editing.
///
/// **Status is not here.** Listing, selling and archiving carry writes beyond
/// the field — see `lib/features/inventory/CLAUDE.md`. The one exception is
/// the count: stock put behind a sold row brings it back, and Overview is
/// where a seller edits it now that Restock is gone.
///
/// **Nor are listings.** What a marketplace asks is edited on Marketplaces
/// management, which the Listings section links to rather than opening boxes
/// of its own.
enum ItemDetailSection {
  overview,
  pricing,
  provenance,
  description,
  notes,
}

/// What the open section has collected that the seller did not type.
///
/// **Typed text stays in the screen's `TextEditingController`s** and arrives
/// as arguments to the save methods, the way the item form already does it: a
/// notifier holding nine boxes rebuilds the screen on every keystroke.
class ItemDetailEditState {
  const ItemDetailEditState({
    this.editing,
    this.isSaving = false,
    this.condition,
    this.sourceId,
    this.categoryId,
    this.locationId,
    this.purchaseDate,
  });

  /// Null when nothing is open. **Only ever one** — a second draft is a
  /// second set of unsaved keystrokes with no way to tell the Saves apart.
  final ItemDetailSection? editing;

  final bool isSaving;

  final ItemCondition? condition;
  final String? sourceId;
  final String? categoryId;
  final String? locationId;
  final DateTime? purchaseDate;

  bool isOpen(ItemDetailSection section) => editing == section;

  ItemDetailEditState copyWith({
    ItemCondition? condition,
    String? sourceId,
    String? categoryId,
    String? locationId,
    DateTime? purchaseDate,
    bool? isSaving,
  }) => ItemDetailEditState(
    editing: editing,
    isSaving: isSaving ?? this.isSaving,
    condition: condition ?? this.condition,
    sourceId: sourceId ?? this.sourceId,
    categoryId: categoryId ?? this.categoryId,
    locationId: locationId ?? this.locationId,
    purchaseDate: purchaseDate ?? this.purchaseDate,
  );
}

/// Opens one section of the item detail screen, and writes it.
///
/// **Every save re-reads the item and applies only its own section's fields.**
/// The record is a stream and a teammate may have changed something else
/// while the draft was open; writing a copy taken when Edit was tapped would
/// silently undo them.
class ItemDetailEditController extends Notifier<ItemDetailEditState> {
  @override
  ItemDetailEditState build() => const ItemDetailEditState();

  /// Opens [section], seeding the choices that are not typed from [item].
  ///
  /// Seeding from the record on every open — rather than once per screen — is
  /// what makes Cancel a restore: closing and reopening reads what is current.
  void edit(ItemDetailSection section, Item item) =>
      state = ItemDetailEditState(
        editing: section,
        condition: item.condition,
        sourceId: item.sourceId,
        categoryId: item.categoryId,
        locationId: item.locationId,
        purchaseDate: item.purchaseDate,
      );

  void cancel() => state = const ItemDetailEditState();

  void selectCondition(ItemCondition condition) =>
      state = state.copyWith(condition: condition);

  void selectSource(String sourceId) =>
      state = state.copyWith(sourceId: sourceId);

  void selectCategory(String categoryId) =>
      state = state.copyWith(categoryId: categoryId);

  void selectLocation(String locationId) =>
      state = state.copyWith(locationId: locationId);

  void selectPurchaseDate(DateTime date) =>
      state = state.copyWith(purchaseDate: date);

  Future<void> saveOverview({
    required String itemId,
    required String title,
    required String quantity,
  }) {
    final String trimmed = title.trim();

    return _write(itemId, ItemDetailSection.overview, (Item current) {
      final Item edited = current.copyWith(
        title: trimmed,
        // One is the answer for almost every reseller item, so an empty or
        // unparseable box means one rather than nothing.
        quantity: int.tryParse(quantity.trim()) ?? 1,
        condition: state.condition,
      );

      // Putting stock behind a sold row is the seller saying they have the
      // thing again — a recorded instant, so the wall clock rather than
      // `clockProvider`.
      return ItemTransition.restocked(edited, now: DateTime.now());
    });
  }

  Future<void> savePricing({
    required String itemId,
    required String purchasePrice,
    required String expectedPrice,
    required String minimumPrice,
  }) {
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? cost = Money.tryParse(purchasePrice, currency);
    final Money? expected = Money.tryParse(expectedPrice, currency);
    final Money? minimum = Money.tryParse(minimumPrice, currency);

    return _write(itemId, ItemDetailSection.pricing, (Item current) {
      // An emptied box is the seller removing the figure, which is not the
      // same as leaving it alone — hence the clear flags (hard rule 5).
      return current.copyWith(
        purchasePrice: cost,
        expectedPrice: expected,
        minimumPrice: minimum,
        clearPurchasePrice: cost == null,
        clearExpectedPrice: expected == null,
        clearMinimumPrice: minimum == null,
      );
    });
  }

  Future<void> saveProvenance({
    required String itemId,
    required String barcode,
  }) {
    final String? code = TextInputUtils.orNull(barcode);

    return _write(itemId, ItemDetailSection.provenance, (Item current) {
      return current.copyWith(
        sourceId: state.sourceId,
        categoryId: state.categoryId,
        locationId: state.locationId,
        purchaseDate: state.purchaseDate,
        barcode: code,
        clearBarcode: code == null,
      );
    });
  }

  Future<void> saveDescription({
    required String itemId,
    required String description,
  }) {
    final String? value = TextInputUtils.orNull(description);

    return _write(itemId, ItemDetailSection.description, (Item current) {
      return current.copyWith(
        description: value,
        clearDescription: value == null,
      );
    });
  }

  Future<void> saveNotes({required String itemId, required String notes}) {
    final String? value = TextInputUtils.orNull(notes);

    return _write(itemId, ItemDetailSection.notes, (Item current) {
      return current.copyWith(notes: value, clearNotes: value == null);
    });
  }

  /// Reads the item fresh, applies [apply], writes it and closes the section.
  Future<void> _write(
    String itemId,
    ItemDetailSection section,
    Item Function(Item current) apply,
  ) async {
    if (state.isSaving) return;

    state = state.copyWith(isSaving: true);
    SdLogger.action(LogTagConstant.item, 'Save item section', <String, Object>{
      'itemId': itemId,
      'section': section.name,
    });

    try {
      final Item? current = await ref
          .read(itemRepositoryProvider)
          .watchItem(itemId)
          .first;

      if (current == null) {
        SdLogger.info(
          LogTagConstant.item,
          'Item section save found no record',
          <String, Object>{'itemId': itemId, 'section': section.name},
        );

        state = const ItemDetailEditState();

        return;
      }

      await ref.read(itemRepositoryProvider).save(apply(current));

      SdLogger.info(LogTagConstant.item, 'Item section saved', <String, Object>{
        'itemId': itemId,
        'section': section.name,
      });

      state = const ItemDetailEditState();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.item,
        'Item section failed to save',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'itemId': itemId, 'section': section.name},
      );

      state = state.copyWith(isSaving: false);

      rethrow;
    }
  }
}

final NotifierProvider<ItemDetailEditController, ItemDetailEditState>
itemDetailEditControllerProvider =
    NotifierProvider<ItemDetailEditController, ItemDetailEditState>(
      ItemDetailEditController.new,
    );
