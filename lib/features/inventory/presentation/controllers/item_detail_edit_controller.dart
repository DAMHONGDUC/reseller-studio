import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/text_input_utils.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';
import '../../domain/services/item_transition.dart';

/// Which block of the item detail screen is open for editing.
///
/// **The verbs are still not here.** Listing, selling and archiving carry
/// writes beyond the field — see `lib/features/inventory/CLAUDE.md`. What
/// [status] and [quantity] are is the seller's own answer to two independent
/// questions: neither writes the other, and a pair that cannot both be true is
/// drawn as an alert tag rather than corrected.
///
/// **Nor are listings.** What a marketplace asks is edited on Marketplaces
/// management, which the Listings section links to rather than opening boxes
/// of its own.
enum ItemDetailSection {
  overview,
  quantity,
  status,
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
    this.status = ItemStatus.draft,
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

  /// What the status section is showing as picked. Meaningless while that
  /// section is closed — [edit] seeds it from the record on every open.
  final ItemStatus status;

  final ItemCondition? condition;
  final String? sourceId;
  final String? categoryId;
  final String? locationId;
  final DateTime? purchaseDate;

  bool isOpen(ItemDetailSection section) => editing == section;

  ItemDetailEditState copyWith({
    ItemStatus? status,
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
        status: item.status,
        condition: item.condition,
        sourceId: item.sourceId,
        categoryId: item.categoryId,
        locationId: item.locationId,
        purchaseDate: item.purchaseDate,
      );

  void cancel() => state = const ItemDetailEditState();

  /// **Nothing is refused** — owner's rule. This is the screen where a seller
  /// corrects what the app got wrong.
  void selectStatus(ItemStatus status) =>
      state = state.copyWith(status: status);

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

  Future<void> saveOverview({required String itemId, required String title}) {
    final String trimmed = title.trim();

    return _write(itemId, ItemDetailSection.overview, (Item current) {
      return current.copyWith(title: trimmed, condition: state.condition);
    });
  }

  /// Writes the count, and nothing else.
  ///
  /// **A count moves no status** — owner's rule. A sold row given stock stays
  /// sold and wears an alert tag saying so; the seller picks the status in its
  /// own section.
  Future<void> saveQuantity({
    required String itemId,
    required String quantity,
  }) {
    // One is the answer for almost every reseller item, so an empty or
    // unparseable box means one rather than nothing.
    final int count = int.tryParse(quantity.trim()) ?? 1;

    return _write(
      itemId,
      ItemDetailSection.quantity,
      (Item current) => current.copyWith(quantity: count),
    );
  }

  /// Writes the status the seller picked, refusing nothing.
  ///
  /// Through `ItemTransition.setStatus`, which is what carries `soldAt` — a
  /// recorded instant, so the wall clock rather than `clockProvider`.
  Future<void> saveStatus({required String itemId}) => _write(
    itemId,
    ItemDetailSection.status,
    (Item current) =>
        ItemTransition.setStatus(current, state.status, now: DateTime.now()),
  );

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
