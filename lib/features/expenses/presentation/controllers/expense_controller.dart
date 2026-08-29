import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../../core/storage/document_picker.dart';
import '../../../../core/storage/file_uploader.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../mock_data/providers.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/services/recurring_expense_schedule.dart';

/// Recording business costs that are not the cost of an item (plan §17).
///
/// **Category, amount and date are required** (plan §28) — an uncategorised
/// expense cannot appear in a tax report, which is most of why the feature
/// exists, and an undated one cannot be placed in a period.
///
/// [orderId] attributes a cost to one sale. Left null it is an overhead, and
/// the two are counted differently: an overhead reduces the workspace's
/// profit, an attributed cost reduces that order's.
class ExpenseController extends Notifier<bool> {
  static const Uuid _uuid = Uuid();

  @override
  bool build() => false;

  Future<void> save({
    required ExpenseCategory category,
    required String amount,
    required DateTime date,
    String? id,
    String? vendor,
    String? notes,
    String? orderId,
    String? receiptUrl,
    double? mileage,
    bool isRecurring = false,
    String? recurringSeriesId,
  }) async {
    final String currency = ref.read(workspaceCurrencyProvider);
    final bool isMileage = category == ExpenseCategory.mileage;
    final Money? typed = Money.tryParse(amount, currency);
    final Money? parsed = typed ?? (isMileage ? Money.zero(currency) : null);
    final String expenseId = id ?? _uuid.v4();

    // A mileage trip is deducted at the authority's published rate per mile,
    // not at what the seller spent, so the money is genuinely optional there
    // — and the tax calculator excludes the category from its own line total,
    // which is what stops the zero from claiming the trip was free.
    if (parsed == null) return;

    state = true;
    SdLogger.action(LogTagConstant.expense, 'Save expense', <String, Object>{
      'expenseId': expenseId,
      'category': category.name,
      'amountMinor': parsed.minor,
      'mileage': mileage ?? 0,
      'isAttributed': orderId != null,
    });
    AppAnalytics.instance.expenseRecorded(category: category.name);

    try {
      await ref
          .read(expenseRepositoryProvider)
          .save(
            Expense(
              id: expenseId,
              category: category,
              amount: parsed,
              date: date,
              createdAt: DateTime.now(),
              vendor: _orNull(vendor),
              notes: _orNull(notes),
              receiptUrl: receiptUrl,
              mileage: mileage,
              orderId: orderId,
              isRecurring: isRecurring,
              recurringSeriesId: recurringSeriesId,
            ),
          );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.expense,
        'Failed to save expense',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{
          'expenseId': expenseId,
          'category': category.name,
        },
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// Post the month a recurring cost is owed for.
  ///
  /// **Copied from the latest occurrence, not the first** — a rent rise
  /// recorded last month carries forward, which is the whole reason the
  /// series points at the newest row rather than the original.
  ///
  /// Two fields are deliberately not copied: the receipt, because next
  /// month's bill is a different document, and `orderId`, because a cost
  /// attributed to one sale is not something that recurs.
  Future<void> recordNext(RecurringExpense series) async {
    final Expense template = series.latest;
    final String expenseId = _uuid.v4();

    state = true;
    SdLogger.action(
      LogTagConstant.expense,
      'Record recurring expense',
      <String, Object>{
        'expenseId': expenseId,
        'seriesId': series.seriesId,
        'category': template.category.name,
        'amountMinor': template.amount.minor,
      },
    );
    AppAnalytics.instance.expenseRecorded(category: template.category.name);

    try {
      await ref
          .read(expenseRepositoryProvider)
          .save(
            Expense(
              id: expenseId,
              category: template.category,
              amount: template.amount,
              date: series.due,
              createdAt: DateTime.now(),
              vendor: template.vendor,
              notes: template.notes,
              mileage: template.mileage,
              isRecurring: true,
              recurringSeriesId: template.seriesId,
            ),
          );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.expense,
        'Failed to record a recurring expense',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{
          'expenseId': expenseId,
          'seriesId': series.seriesId,
        },
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// Photograph or choose a receipt and store it, returning its URL.
  ///
  /// Uploaded now rather than at save, so a seller who photographs a receipt
  /// and then loses signal has one upload to retry rather than a form that
  /// will not submit. Returns null when they cancelled — not an error.
  Future<String?> attachReceipt({
    required String recordId,
    required bool fromCamera,
  }) async {
    state = true;

    try {
      return await DocumentPicker.pickAndUpload(
        uploader: ref.read(fileUploaderProvider),
        folder: FileFolder.receipts,
        recordId: recordId,
        fromCamera: fromCamera,
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.expense,
        'Failed to attach a receipt',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'recordId': recordId},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> delete(String id) async {
    state = true;
    SdLogger.action(LogTagConstant.expense, 'Delete expense', <String, Object>{
      'expenseId': id,
    });

    try {
      await ref.read(expenseRepositoryProvider).delete(id);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.expense,
        'Failed to delete expense',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'expenseId': id},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  static String? _orNull(String? value) {
    final String trimmed = value?.trim() ?? '';

    return trimmed.isEmpty ? null : trimmed;
  }
}

final NotifierProvider<ExpenseController, bool> expenseControllerProvider =
    NotifierProvider<ExpenseController, bool>(ExpenseController.new);

/// The label for an expense category.
///
/// `domain/` holds no strings (hard rule 7), so the enum carries the concept
/// and this carries the words.
final class ExpenseCategoryLabel {
  static String of(ExpenseCategory category) => switch (category) {
    ExpenseCategory.shipping => 'Shipping',
    ExpenseCategory.packaging => 'Packaging',
    ExpenseCategory.advertising => 'Advertising',
    ExpenseCategory.storage => 'Storage',
    ExpenseCategory.mileage => 'Mileage',
    ExpenseCategory.equipment => 'Equipment',
    ExpenseCategory.software => 'Software',
    ExpenseCategory.repairs => 'Repairs',
    ExpenseCategory.other => 'Other',
  };
}
