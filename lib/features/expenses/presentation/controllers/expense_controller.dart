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
  }) async {
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? parsed = Money.tryParse(amount, currency);
    final String expenseId = id ?? _uuid.v4();

    if (parsed == null) return;

    state = true;
    SdLogger.action(LogTagConstant.expense, 'Save expense', <String, Object>{
      'expenseId': expenseId,
      'category': category.name,
      'amountMinor': parsed.minor,
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
