/// Riverpod wiring for `reports` — what the business can hand to somebody
/// else.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/time/app_clock.dart';
import '../orders/domain/entities/order.dart';
import '../orders/providers.dart';
import '../sourcing/domain/entities/purchase.dart';
import '../sourcing/providers.dart';
import '../tax/domain/entities/tax_year.dart';
import '../tax/providers.dart';
import 'domain/services/bookkeeping_gaps.dart';

/// Everywhere the books are still guessing.
///
/// Derived on read like every other figure (hard rule 3): entering one fee
/// removes one row here and corrects every total that depended on it, with no
/// job to run and nothing to invalidate.
final Provider<BookkeepingGaps> bookkeepingGapsProvider =
    Provider<BookkeepingGaps>((Ref ref) {
      return BookkeepingGaps.from(
        orders: ref.watch(ordersProvider).value ?? const <Order>[],
        purchases: ref.watch(purchasesProvider).value ?? const <Purchase>[],
        now: ref.watch(clockProvider).now(),
      );
    });

/// The same holes, narrowed to the tax year on screen.
///
/// **What makes the export worth handing over.** A summary is only as exact
/// as the rows under it, so the pack carries "128 sales checked, 0 estimated"
/// — and a gap in a year already filed is not work this return is waiting on,
/// which is why this is scoped and `bookkeepingGapsProvider` is not.
final Provider<BookkeepingGaps> taxYearGapsProvider = Provider<BookkeepingGaps>(
  (Ref ref) {
    final TaxYear year = ref.watch(selectedTaxYearProvider);

    return BookkeepingGaps.from(
      orders: ref.watch(ordersProvider).value ?? const <Order>[],
      purchases: ref.watch(purchasesProvider).value ?? const <Purchase>[],
      now: ref.watch(clockProvider).now(),
      from: year.start,
      toExclusive: year.endExclusive,
    );
  },
);
