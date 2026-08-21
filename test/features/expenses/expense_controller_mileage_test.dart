import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:seller_os/features/expenses/domain/entities/expense.dart';
import 'package:seller_os/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:seller_os/features/expenses/providers.dart';
import 'package:seller_os/features/listings/domain/enums/listing_status.dart';

import '../../support/pump_app.dart';

/// A mileage trip is the one expense whose money is optional.
///
/// The deduction comes from the distance and the authority's published rate,
/// so a trip with no fuel receipt still has to save — and `TaxSummaryCalculator`
/// drops any mileage row with no distance, which is what made an unrecorded
/// distance a permanently empty tax line.
void main() {
  Future<Expense?> saved(ProviderContainer container, String id) async {
    await warmUp(container);

    final List<Expense> all =
        container.read(expensesProvider).value ?? const <Expense>[];

    return all.where((Expense expense) => expense.id == id).firstOrNull;
  }

  test('a mileage trip saves with no amount, keeping its distance', () async {
    final ProviderContainer container = mockContainer();

    await container
        .read(expenseControllerProvider.notifier)
        .save(
          id: 'exp-trip',
          category: ExpenseCategory.mileage,
          amount: '',
          date: testNow,
          mileage: 12.5,
        );

    final Expense? expense = await saved(container, 'exp-trip');

    expect(expense, isNotNull);
    expect(expense!.mileage, 12.5);
    // Zero rather than null because `Money` is not nullable on an expense —
    // and the tax calculator excludes the mileage category from its own line
    // total, so the zero never claims the trip was free.
    expect(expense.amount.minor, 0);
  });

  test('every other category still refuses to save without an amount', () async {
    final ProviderContainer container = mockContainer();

    await container
        .read(expenseControllerProvider.notifier)
        .save(
          id: 'exp-packaging',
          category: ExpenseCategory.packaging,
          amount: '',
          date: testNow,
        );

    expect(await saved(container, 'exp-packaging'), isNull);
  });
}
