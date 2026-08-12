import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/money/money.dart';
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
    double? mileage,
    bool isRecurring = false,
  }) async {
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? parsed = Money.tryParse(amount, currency);
    final String expenseId = id ?? _uuid.v4();

    if (parsed == null) return;

    state = true;
    AppLogger.action('Save expense', <String, Object>{
      'expenseId': expenseId,
      'category': category.name,
      'amountMinor': parsed.minor,
      'isAttributed': orderId != null,
    });

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
              mileage: mileage,
              orderId: orderId,
              isRecurring: isRecurring,
            ),
          );
    } catch (error, stackTrace) {
      AppLogger.error(
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

  Future<void> delete(String id) async {
    state = true;
    AppLogger.action('Delete expense', <String, Object>{'expenseId': id});

    try {
      await ref.read(expenseRepositoryProvider).delete(id);
    } catch (error, stackTrace) {
      AppLogger.error(
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
