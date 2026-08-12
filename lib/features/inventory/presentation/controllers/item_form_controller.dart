import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/money/money.dart';
import '../../../../core/storage/file_uploader.dart';
import '../../../mock_data/providers.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';

/// The choices on the Add/Edit Item form that are not typed.
///
/// **Text stays in the screen's `TextEditingController`s and arrives as
/// arguments to [ItemFormController.submit].** Holding nine text fields in a
/// notifier would rebuild the whole form on every keystroke, and the parsing
/// still has to happen in one place — which is `submit`, where it does.
class ItemFormState {
  const ItemFormState({
    this.itemId,
    this.status = ItemStatus.draft,
    this.condition,
    this.categoryId,
    this.locationId,
    this.sourceId,
    this.purchaseId,
    this.purchaseDate,
    this.photoUrls = const <String>[],
    this.createdAt,
    this.isSaving = false,
    this.isUploadingPhoto = false,
  });

  /// Null while creating, set while editing. What decides whether [submit]
  /// writes a new document or merges into an existing one.
  final String? itemId;

  final ItemStatus status;
  final ItemCondition? condition;
  final String? categoryId;
  final String? locationId;
  final String? sourceId;
  final String? purchaseId;
  final DateTime? purchaseDate;
  final List<String> photoUrls;

  /// Preserved across an edit so the item keeps its original creation time —
  /// `createdAt` is what Inventory sorts by, and refreshing it on every save
  /// would shuffle the list every time somebody fixed a typo.
  final DateTime? createdAt;

  final bool isSaving;
  final bool isUploadingPhoto;

  bool get isEditing => itemId != null;

  ItemFormState copyWith({
    String? itemId,
    ItemStatus? status,
    ItemCondition? condition,
    String? categoryId,
    String? locationId,
    String? sourceId,
    String? purchaseId,
    DateTime? purchaseDate,
    List<String>? photoUrls,
    DateTime? createdAt,
    bool? isSaving,
    bool? isUploadingPhoto,
  }) => ItemFormState(
    itemId: itemId ?? this.itemId,
    status: status ?? this.status,
    condition: condition ?? this.condition,
    categoryId: categoryId ?? this.categoryId,
    locationId: locationId ?? this.locationId,
    sourceId: sourceId ?? this.sourceId,
    purchaseId: purchaseId ?? this.purchaseId,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    photoUrls: photoUrls ?? this.photoUrls,
    createdAt: createdAt ?? this.createdAt,
    isSaving: isSaving ?? this.isSaving,
    isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
  );
}

/// Add Item and Edit Item — the same form, because they are the same fields.
///
/// **Only the title is required** (hard rule 2, plan §28). Everything else is
/// something a seller may fill in later or never, and the extra requirements
/// attach when the item *moves* — see `ItemTransition`. Adding a required
/// field here needs explicit approval.
class ItemFormController extends Notifier<ItemFormState> {
  static const Uuid _uuid = Uuid();

  /// How wide a photo is stored at.
  ///
  /// 1600 is enough for a marketplace listing and small enough that a seller
  /// on a phone plan is not uploading eight megabytes per item — the Storage
  /// rules cap at 15MB, and that cap is a backstop, not a target.
  static const double photoMaxWidth = 1600;
  static const int photoQuality = 85;

  @override
  ItemFormState build() => const ItemFormState();

  /// Start a fresh create form.
  void startCreate() => state = const ItemFormState();

  /// Load an existing item into the form.
  ///
  /// Called once by the screen when the item arrives; calling it again on
  /// every rebuild would throw away whatever the seller had just changed.
  void seed(Item item) => state = ItemFormState(
    itemId: item.id,
    status: item.status,
    condition: item.condition,
    categoryId: item.categoryId,
    locationId: item.locationId,
    sourceId: item.sourceId,
    purchaseId: item.purchaseId,
    purchaseDate: item.purchaseDate,
    photoUrls: item.photoUrls,
    createdAt: item.createdAt,
  );

  void selectCondition(ItemCondition value) =>
      state = state.copyWith(condition: value);

  void selectCategory(String? id) => state = state.copyWith(categoryId: id);

  void selectLocation(String? id) => state = state.copyWith(locationId: id);

  void selectSource(String? id) => state = state.copyWith(sourceId: id);

  void selectPurchaseDate(DateTime date) =>
      state = state.copyWith(purchaseDate: date);

  void removePhoto(String url) => state = state.copyWith(
    photoUrls: state.photoUrls
        .where((String existing) => existing != url)
        .toList(),
  );

  /// Pick a photo and store it.
  ///
  /// The upload happens now rather than at save, so a seller who takes four
  /// photos and then loses signal has four uploads to retry rather than a
  /// form that will not submit.
  Future<void> addPhoto({required bool fromCamera}) async {
    final FileUploader uploader = ref.read(fileUploaderProvider);
    final String recordId = state.itemId ?? _uuid.v4();

    state = state.copyWith(isUploadingPhoto: true);

    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: photoMaxWidth,
        imageQuality: photoQuality,
      );

      if (picked == null) {
        // A cancelled picker is not a failure and is not logged as one.
        return;
      }

      final String url = await uploader.upload(
        folder: FileFolder.items,
        recordId: recordId,
        filePath: picked.path,
      );

      state = state.copyWith(
        itemId: state.itemId,
        photoUrls: <String>[...state.photoUrls, url],
      );

      AppLogger.info('Item photo attached', <String, Object>{
        'recordId': recordId,
        'count': state.photoUrls.length,
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to attach item photo',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'fromCamera': fromCamera},
      );

      rethrow;
    } finally {
      state = state.copyWith(isUploadingPhoto: false);
    }
  }

  /// Write the item and return its id, or null when there is no title.
  ///
  /// Every money field is parsed with `Money.tryParse`, which returns **null
  /// for an empty box** — an untyped cost stays unknown and renders `—`
  /// rather than claiming the item was free (hard rule 4).
  Future<String?> submit({
    required String title,
    String quantity = '',
    String sku = '',
    String barcode = '',
    String purchasePrice = '',
    String askingPrice = '',
    String minimumPrice = '',
    String description = '',
    String notes = '',
  }) async {
    final String trimmed = title.trim();
    final String currency = ref.read(workspaceCurrencyProvider);
    final String id = state.itemId ?? _uuid.v4();
    final DateTime now = DateTime.now();

    if (trimmed.isEmpty || state.isSaving) return null;

    state = state.copyWith(isSaving: true);
    AppLogger.action('Item form submitted', <String, Object>{
      'itemId': id,
      'isEditing': state.isEditing,
      'photos': state.photoUrls.length,
    });

    try {
      final Item item = Item(
        id: id,
        title: trimmed,
        // One is the answer for almost every reseller item, so an empty or
        // unparseable box means one rather than nothing.
        quantity: int.tryParse(quantity.trim()) ?? 1,
        status: state.status,
        createdAt: state.createdAt ?? now,
        purchasePrice: Money.tryParse(purchasePrice, currency),
        askingPrice: Money.tryParse(askingPrice, currency),
        minimumPrice: Money.tryParse(minimumPrice, currency),
        purchaseId: state.purchaseId,
        sourceId: state.sourceId,
        categoryId: state.categoryId,
        locationId: state.locationId,
        sku: _orNull(sku),
        barcode: _orNull(barcode),
        condition: state.condition,
        description: _orNull(description),
        notes: _orNull(notes),
        photoUrls: state.photoUrls,
        purchaseDate: state.purchaseDate,
      );

      await ref.read(itemRepositoryProvider).save(item);

      AppLogger.info('Item form saved', <String, Object>{
        'itemId': id,
        'status': item.status.name,
      });

      if (!state.isEditing) {
        AppAnalytics.instance.itemCreated(
          viaQuickAdd: false,
          hasPhoto: state.photoUrls.isNotEmpty,
        );
      }

      return id;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Item form failed to save',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'itemId': id, 'isEditing': state.isEditing},
      );

      rethrow;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  /// An empty box means "not entered", which is a null field rather than an
  /// empty string — the two look identical on screen and completely different
  /// in a query.
  static String? _orNull(String value) {
    final String trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }
}

final NotifierProvider<ItemFormController, ItemFormState>
itemFormControllerProvider =
    NotifierProvider<ItemFormController, ItemFormState>(
      ItemFormController.new,
    );
