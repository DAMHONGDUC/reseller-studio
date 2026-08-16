/// Riverpod wiring for `tax` — the year-end summary (plan §20).
///
/// **Everything is derived at read time** (hard rule 3). A fee corrected in
/// March changes last year's summary the next time it is opened, which is
/// exactly what a return needs and exactly what a stored total would not do.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../core/time/app_clock.dart';
import '../expenses/domain/entities/expense.dart';
import '../expenses/providers.dart';
import '../orders/domain/entities/order.dart';
import '../orders/providers.dart';
import '../workspace/providers.dart';
import 'domain/entities/tax_summary.dart';
import 'domain/entities/tax_year.dart';
import 'domain/enums/tax_jurisdiction.dart';
import 'domain/services/tax_summary_calculator.dart';

/// Which country's rules this workspace files under.
///
/// Read from the workspace rather than the device locale: a seller on holiday
/// does not change tax jurisdiction, and a phone set to `en_US` says nothing
/// about where a business is registered.
final Provider<TaxJurisdiction> taxJurisdictionProvider =
    Provider<TaxJurisdiction>((Ref ref) {
      final String country =
          ref.watch(currentWorkspaceProvider)?.country ?? AppEnv.defaultCountry;

      return TaxJurisdiction.fromCountryCode(country);
    });

/// The year the screen opens on: the one today falls in.
///
/// Reads [clockProvider] rather than `DateTime.now()` — this is a *derived*
/// figure, so a test pins it and the same assertion cannot pass in one tax
/// year and fail in the next.
final Provider<TaxYear> currentTaxYearProvider = Provider<TaxYear>((Ref ref) {
  return TaxYear.containing(
    ref.watch(clockProvider).now(),
    ref.watch(taxJurisdictionProvider),
  );
});

/// Which year the screen is showing. Starts at [currentTaxYearProvider].
class SelectedTaxYearController extends Notifier<TaxYear> {
  @override
  TaxYear build() => ref.watch(currentTaxYearProvider);

  void select(TaxYear year) => state = year;
}

final NotifierProvider<SelectedTaxYearController, TaxYear>
selectedTaxYearProvider = NotifierProvider<SelectedTaxYearController, TaxYear>(
  SelectedTaxYearController.new,
);

/// The years the picker offers: this one and the four behind it.
///
/// **Backwards only.** A return is filed for a year that has happened; a
/// forward year would show an empty summary and read as a bug.
final Provider<List<TaxYear>> selectableTaxYearsProvider =
    Provider<List<TaxYear>>((Ref ref) {
      TaxYear year = ref.watch(currentTaxYearProvider);

      final List<TaxYear> years = <TaxYear>[year];

      for (int i = 0; i < TaxConstant.selectableYearsBack; i++) {
        year = year.previous;
        years.add(year);
      }

      return years;
    });

final Provider<TaxSummary> taxSummaryProvider = Provider<TaxSummary>((Ref ref) {
  return TaxSummaryCalculator.of(
    year: ref.watch(selectedTaxYearProvider),
    orders: ref.watch(ordersProvider).value ?? const <Order>[],
    expenses: ref.watch(expensesProvider).value ?? const <Expense>[],
    currency: ref.watch(workspaceCurrencyProvider),
  );
});

/// The numbers this feature's wiring needs, out of the providers.
final class TaxConstant {
  /// How many closed years the picker offers behind the current one. Four
  /// covers both authorities' amendment windows with room to spare.
  static const int selectableYearsBack = 4;
}
