/// Riverpod wiring for `expenses`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../mock_data/providers.dart';
import 'domain/entities/expense.dart';

final StreamProvider<List<Expense>> expensesProvider =
    StreamProvider<List<Expense>>((Ref ref) {
      return ref.watch(expenseRepositoryProvider).watchExpenses();
    });
