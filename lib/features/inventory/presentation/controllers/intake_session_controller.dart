import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../mock_data/providers.dart';
import '../../../sourcing/domain/entities/purchase.dart';
import '../../../sourcing/domain/repositories/sourcing_repository.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';
import '../../domain/repositories/item_repository.dart';

/// One thing taken in during a session, as the screen lists it back.
///
/// It holds the id because the item is **already written** — the list is a
/// record of what happened, not a basket waiting to be saved.
class IntakeLine {
  const IntakeLine({required this.itemId, required this.title, this.cost});

  final String itemId;
  final String title;

  /// Null when the seller did not enter one. Never zero (hard rule 4) — a
  /// blank box means nobody said, and a free item is a different claim.
  final Money? cost;
}

/// A buying trip in progress.
class IntakeSessionState {
  const IntakeSessionState({
    required this.purchaseDate,
    this.sourceId,
    this.lines = const <IntakeLine>[],
    this.isSaving = false,
    this.isFinished = false,
  });

  /// One date for the whole trip, chosen once.
  final DateTime purchaseDate;

  /// Where the trip was. Optional (hard rule 2): a seller may record what
  /// they bought before recording where they bought it.
  final String? sourceId;

  final List<IntakeLine> lines;
  final bool isSaving;

  /// Set once the purchase is written, so the screen knows to leave.
  final bool isFinished;

  /// What the trip cost, across the lines that named a price.
  ///
  /// Null when none did — `totalOfKnown` deliberately does not read a missing
  /// cost as zero, which would claim those items were free.
  Money? get knownTotal =>
      lines.map((IntakeLine line) => line.cost).totalOfKnown();

  int get count => lines.length;

  IntakeSessionState copyWith({
    DateTime? purchaseDate,
    String? sourceId,
    List<IntakeLine>? lines,
    bool? isSaving,
    bool? isFinished,
  }) => IntakeSessionState(
    purchaseDate: purchaseDate ?? this.purchaseDate,
    sourceId: sourceId ?? this.sourceId,
    lines: lines ?? this.lines,
    isSaving: isSaving ?? this.isSaving,
    isFinished: isFinished ?? this.isFinished,
  );
}

/// Taking in a whole buying trip, one line at a time.
///
/// **The batch sibling of Quick Add, and it exists for the number Quick Add
/// cannot ask for.** A reseller comes back from a thrift store or an estate
/// sale with thirty things bought from one source on one day, and the cost is
/// the only figure that exists solely in that moment — a week later nobody
/// remembers whether the jumper was $3 or $5. A missing cost makes every
/// profit figure downstream `—` (hard rule 5), so this is the flow that feeds
/// the whole "insight" half of the product.
///
/// **It does not add a required field** (hard rule 2). The cost box is
/// optional exactly as it is everywhere else; what changes is that it sits
/// under the seller's thumb at the one moment they know the answer, and that
/// the source and the date are asked once for the trip instead of once per
/// item.
///
/// **Each item is written as it is typed, and the purchase is written at the
/// end.** That ordering is deliberate:
/// - an abandoned session still leaves every item the seller entered, with its
///   cost, its source and its date — nothing typed is lost;
/// - and it leaves no purchase document, because there was no completed trip.
///   A purchase created up front would be an empty record of a trip that never
///   happened, and a `purchaseId` stamped on items before it existed would
///   dangle.
class IntakeSessionController extends Notifier<IntakeSessionState> {
  static const Uuid _uuid = Uuid();

  @override
  IntakeSessionState build() =>
      IntakeSessionState(purchaseDate: DateTime.now());

  void selectSource(String? sourceId) =>
      state = IntakeSessionState(
        purchaseDate: state.purchaseDate,
        sourceId: sourceId,
        lines: state.lines,
        isSaving: state.isSaving,
        isFinished: state.isFinished,
      );

  void selectDate(DateTime date) => state = state.copyWith(purchaseDate: date);

  /// Write one item and add it to the list. Returns false when there was
  /// nothing to write.
  Future<bool> add({required String title, Money? cost}) async {
    final String trimmed = title.trim();
    final String id = _uuid.v4();
    final ItemRepository repository = ref.read(itemRepositoryProvider);

    // The same whole of the validation Quick Add has: a title with something
    // in it (hard rule 2).
    if (trimmed.isEmpty || state.isSaving) return false;

    state = state.copyWith(isSaving: true);
    SdLogger.action(LogTagConstant.intake, 'Intake line', <String, Object>{
      'itemId': id,
      'hasCost': cost != null,
      'hasSource': state.sourceId != null,
    });

    try {
      await repository.save(
        Item(
          id: id,
          title: trimmed,
          quantity: 1,
          status: ItemStatus.draft,
          createdAt: DateTime.now(),
          purchasePrice: cost,
          sourceId: state.sourceId,
          purchaseDate: state.purchaseDate,
        ),
      );

      state = state.copyWith(
        isSaving: false,
        lines: <IntakeLine>[
          IntakeLine(itemId: id, title: trimmed, cost: cost),
          ...state.lines,
        ],
      );
      AppAnalytics.instance.itemCreated(viaQuickAdd: true, hasPhoto: false);

      return true;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.intake,
        'Intake line failed to save',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'itemId': id},
      );

      state = state.copyWith(isSaving: false);

      rethrow;
    }
  }

  /// Close the trip: write the purchase, then point every item at it.
  Future<void> finish({Money? receiptTotal}) async {
    final List<IntakeLine> lines = state.lines;
    final String purchaseId = _uuid.v4();
    final PurchaseRepository purchases = ref.read(purchaseRepositoryProvider);
    final ItemRepository items = ref.read(itemRepositoryProvider);

    if (lines.isEmpty || state.isSaving) return;

    state = state.copyWith(isSaving: true);
    SdLogger.action(LogTagConstant.intake, 'Finish intake', <String, Object>{
      'purchaseId': purchaseId,
      'lines': lines.length,
      'hasReceiptTotal': receiptTotal != null,
    });

    try {
      await purchases.save(
        Purchase(
          id: purchaseId,
          purchaseDate: state.purchaseDate,
          createdAt: DateTime.now(),
          sourceId: state.sourceId,
          // What left the seller's pocket, and only if they said so. The sum
          // of the item costs is an apportionment, not a receipt — see
          // `Purchase.totalCost`, which is the one field allowed to disagree
          // with its items.
          totalCost: receiptTotal,
          itemCount: lines.length,
        ),
      );

      await items.saveAll(<Item>[
        for (final IntakeLine line in lines)
          Item(
            id: line.itemId,
            title: line.title,
            quantity: 1,
            status: ItemStatus.draft,
            createdAt: DateTime.now(),
            purchasePrice: line.cost,
            purchaseId: purchaseId,
            sourceId: state.sourceId,
            purchaseDate: state.purchaseDate,
          ),
      ]);

      SdLogger.info(LogTagConstant.intake, 'Intake finished', <String, Object>{
        'purchaseId': purchaseId,
        'items': lines.length,
      });

      state = state.copyWith(isSaving: false, isFinished: true);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.intake,
        'Failed to finish intake',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{
          'purchaseId': purchaseId,
          'lines': lines.length,
        },
      );

      state = state.copyWith(isSaving: false);

      rethrow;
    }
  }
}

final NotifierProvider<IntakeSessionController, IntakeSessionState>
intakeSessionControllerProvider =
    NotifierProvider<IntakeSessionController, IntakeSessionState>(
      IntakeSessionController.new,
    );
