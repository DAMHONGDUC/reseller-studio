import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/photo_constant.dart';
import '../../../../core/money/money.dart';
import '../../../../core/storage/file_uploader.dart';
import '../../../../core/utils/text_input_utils.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../mock_data/providers.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';
import '../../domain/services/item_transition.dart';

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
    this.savedStatus = ItemStatus.draft,
    this.condition,
    this.categoryId,
    this.locationId,
    this.sourceId,
    this.purchaseId,
    this.purchaseDate,
    this.photoUrls = const <String>[],
    this.createdAt,
    this.listedAt,
    this.soldAt,
    this.isSaving = false,
    this.isUploadingPhoto = false,
    this.listingPrices = const <String, Money>{},
  });

  /// Null while creating, set while editing. What decides whether [submit]
  /// writes a new document or merges into an existing one.
  final String? itemId;

  /// The status the form will write — the seeded one until the seller picks
  /// another.
  final ItemStatus status;

  /// What the record says today, kept because a move has to start from where
  /// the item actually is: `ItemTransition.apply` refuses a jump it is asked
  /// to make from its own destination.
  final ItemStatus savedStatus;

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

  /// Carried for the same reason, and it is not cosmetic: [submit] builds a
  /// whole `Item`, so a timestamp the form does not hold is one that saving a
  /// typo fix erases. Losing `listedAt` resets the staleness clock and drops
  /// the row out of days-to-sell; losing `soldAt` unfiles a sale.
  final DateTime? listedAt;
  final DateTime? soldAt;

  final bool isSaving;
  final bool isUploadingPhoto;

  /// New prices for the item's live listings, by listing id.
  ///
  /// **The marketplace prices are edited in this form, not on another
  /// screen** — owner's rule. They ride here rather than in the text
  /// controllers because a listing is a separate document: [submit] has to
  /// know which ones moved, and a map keyed by id is that answer without
  /// re-reading the stream to diff it.
  ///
  /// Only what the seller changed. An untouched listing is absent, so saving
  /// an item nobody repriced writes no listing at all.
  final Map<String, Money> listingPrices;

  bool get isEditing => itemId != null;

  ItemFormState copyWith({
    String? itemId,
    ItemStatus? status,
    ItemStatus? savedStatus,
    ItemCondition? condition,
    String? categoryId,
    String? locationId,
    String? sourceId,
    String? purchaseId,
    DateTime? purchaseDate,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? listedAt,
    DateTime? soldAt,
    bool? isSaving,
    bool? isUploadingPhoto,
    Map<String, Money>? listingPrices,
  }) => ItemFormState(
    itemId: itemId ?? this.itemId,
    status: status ?? this.status,
    savedStatus: savedStatus ?? this.savedStatus,
    condition: condition ?? this.condition,
    categoryId: categoryId ?? this.categoryId,
    locationId: locationId ?? this.locationId,
    sourceId: sourceId ?? this.sourceId,
    purchaseId: purchaseId ?? this.purchaseId,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    photoUrls: photoUrls ?? this.photoUrls,
    createdAt: createdAt ?? this.createdAt,
    listedAt: listedAt ?? this.listedAt,
    soldAt: soldAt ?? this.soldAt,
    isSaving: isSaving ?? this.isSaving,
    isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
    listingPrices: listingPrices ?? this.listingPrices,
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
    savedStatus: item.status,
    condition: item.condition,
    categoryId: item.categoryId,
    locationId: item.locationId,
    sourceId: item.sourceId,
    purchaseId: item.purchaseId,
    purchaseDate: item.purchaseDate,
    photoUrls: item.photoUrls,
    createdAt: item.createdAt,
    listedAt: item.listedAt,
    soldAt: item.soldAt,
  );

  /// Take the pick. The move itself happens in [submit], where the record is
  /// written — a status changed on a form the seller then abandons is one
  /// nothing should have saved.
  void selectStatus(ItemStatus value) => state = state.copyWith(status: value);

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
        maxWidth: PhotoConstant.maxWidth,
        imageQuality: PhotoConstant.quality,
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

      SdLogger.info(
        LogTagConstant.item,
        'Item photo attached',
        <String, Object>{'recordId': recordId, 'count': state.photoUrls.length},
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.item,
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
  /// Writes the repriced listings alongside the item.
  ///
  /// **One `saveAll`, after the item.** The seller pressed Save once, so a
  /// price landing without the item it belongs to is a state nobody can read
  /// back — and the item is written first because it is the record the
  /// listings point at.
  ///
  /// Reads the listings fresh rather than holding them from when the form
  /// opened: a teammate may have changed a title in between, and only the
  /// price is this form's to move.
  Future<void> _saveListingPrices(String itemId) async {
    if (state.listingPrices.isEmpty) return;

    final List<Listing> listings = await ref
        .read(listingRepositoryProvider)
        .watchListingsForItem(itemId)
        .first;
    final List<Listing> changed = <Listing>[
      for (final Listing listing in listings)
        if (state.listingPrices[listing.id] != null &&
            state.listingPrices[listing.id] != listing.price)
          listing.copyWith(price: state.listingPrices[listing.id]),
    ];

    if (changed.isEmpty) return;

    await ref.read(listingRepositoryProvider).saveAll(changed);
  }

  /// Reprice one of the item's live listings. Null puts it back to whatever
  /// the listing already says, by dropping the edit.
  void setListingPrice(String listingId, Money? price) {
    final Map<String, Money> next = <String, Money>{...state.listingPrices};

    if (price == null) {
      next.remove(listingId);
    } else {
      next[listingId] = price;
    }

    state = state.copyWith(listingPrices: next);
  }

  Future<String?> submit({
    required String title,
    String quantity = '',
    String sku = '',
    String barcode = '',
    String purchasePrice = '',
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
    SdLogger.action(
      LogTagConstant.item,
      'Item form submitted',
      <String, Object>{
        'itemId': id,
        'isEditing': state.isEditing,
        'photos': state.photoUrls.length,
      },
    );

    try {
      final Item item = Item(
        id: id,
        title: trimmed,
        // One is the answer for almost every reseller item, so an empty or
        // unparseable box means one rather than nothing.
        quantity: int.tryParse(quantity.trim()) ?? 1,
        // The status the record has, not the one that was picked: a move has
        // to start from where the item is, and `apply` below is what makes it.
        status: state.savedStatus,
        createdAt: state.createdAt ?? now,
        purchasePrice: Money.tryParse(purchasePrice, currency),
        minimumPrice: Money.tryParse(minimumPrice, currency),
        purchaseId: state.purchaseId,
        sourceId: state.sourceId,
        categoryId: state.categoryId,
        locationId: state.locationId,
        sku: TextInputUtils.orNull(sku),
        barcode: TextInputUtils.orNull(barcode),
        condition: state.condition,
        description: TextInputUtils.orNull(description),
        notes: TextInputUtils.orNull(notes),
        photoUrls: state.photoUrls,
        purchaseDate: state.purchaseDate,
        listedAt: state.listedAt,
        soldAt: state.soldAt,
      );

      // **A picked status is never refused** — owner's rule: the form is where
      // a seller corrects what the app got wrong. It still goes through the
      // transition, which is what carries the side effects — a sold row loses
      // its count, a returning one loses its sold date.
      final Item moved = state.status == state.savedStatus
          ? item
          : ItemTransition.setStatus(item, state.status, now: now);

      // Putting stock behind a sold row is the seller saying they have the
      // thing again — the domain decides what that means, not the form.
      final Item saved = ItemTransition.restocked(moved, now: now);

      await ref.read(itemRepositoryProvider).save(saved);
      await _saveListingPrices(id);

      SdLogger.info(LogTagConstant.item, 'Item form saved', <String, Object>{
        'itemId': id,
        'status': saved.status.name,
        'repriced': state.listingPrices.length,
      });

      if (!state.isEditing) {
        AppAnalytics.instance.itemCreated(
          viaQuickAdd: false,
          hasPhoto: state.photoUrls.isNotEmpty,
        );
      }

      return id;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.item,
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
}

final NotifierProvider<ItemFormController, ItemFormState>
itemFormControllerProvider =
    NotifierProvider<ItemFormController, ItemFormState>(ItemFormController.new);
