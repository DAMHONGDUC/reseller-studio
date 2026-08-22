import '../../../../core/money/money.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../orders/domain/entities/order.dart';
import '../entities/mileage_journey.dart';
import '../entities/tax_category.dart';
import '../entities/tax_summary.dart';
import '../entities/tax_year.dart';
import 'mileage_calculator.dart';

/// Folds a year's orders and expenses into the lines a return asks for
/// (plan §20).
///
/// **Pure, and it takes the rows rather than reading them** — the same shape
/// as `ProfitCalculator`, and for the same reason: the interesting cases are
/// a year boundary and a missing cost, and a service that fetched its own
/// data could not be tested at either.
final class TaxSummaryCalculator {
  static TaxSummary of({
    required TaxYear year,
    required List<Order> orders,
    required List<Expense> expenses,
    required String currency,
  }) {
    // **Net revenue, the same definition Analytics uses.** A cancelled order
    // never earned anything and a refunded one gave it back, so counting
    // either would put money on a tax return the seller never kept.
    final List<Order> inYear = orders
        .where(
          (Order order) =>
              order.status.countsAsRevenue && year.contains(order.orderedAt),
        )
        .toList();

    final List<Expense> costs = expenses
        .where(
          (Expense expense) =>
              !expense.isDeleted && year.contains(expense.date),
        )
        .toList();

    final Money zero = Money.zero(currency);

    final Money? revenue = inYear
        .map((Order order) => order.salePrice - (order.refund ?? zero))
        .totalOrNull();

    final Money? costOfGoods = inYear
        .map((Order order) => order.costOfGoods)
        .totalOfKnown();

    final List<MileageJourney> journeys = _journeys(costs);

    return TaxSummary(
      year: year,
      revenue: revenue,
      costOfGoods: costOfGoods,
      lines: _lines(year, costs),
      mileageDistance: _distance(journeys),
      mileageDeduction: _mileage(year, journeys, currency),
      currency: currency,
    );
  }

  /// Every line the form has, in the form's order — including the empty ones.
  ///
  /// **Mileage is deliberately excluded from its own line's money total.** It
  /// is deducted at the published rate per mile, not at what the seller spent
  /// on fuel, so adding the recorded amount as well would double-count the
  /// same journey.
  static List<TaxLineTotal> _lines(TaxYear year, List<Expense> expenses) {
    final List<TaxCategory> categories = TaxCategoryConstant.of(
      year.jurisdiction,
    );

    return <TaxLineTotal>[
      for (final TaxCategory category in categories)
        TaxLineTotal(
          line: category.line,
          amount: expenses
              .where(
                (Expense expense) =>
                    category.expenses.contains(expense.category) &&
                    expense.category != ExpenseCategory.mileage,
              )
              .map((Expense expense) => expense.amount)
              .totalOrNull(),
        ),
    ];
  }

  /// An expense with no distance recorded is not a journey worth nothing; it
  /// is one nobody measured, so it is dropped rather than counted as zero.
  static List<MileageJourney> _journeys(List<Expense> expenses) => expenses
      .where(
        (Expense expense) =>
            expense.category == ExpenseCategory.mileage &&
            expense.mileage != null,
      )
      .map(
        (Expense expense) =>
            MileageJourney(date: expense.date, distance: expense.mileage!),
      )
      .toList();

  static double _distance(List<MileageJourney> journeys) => journeys.fold(
    0,
    (double running, MileageJourney journey) => running + journey.distance,
  );

  /// **Banded over the year's total, rated per journey.** The band is
  /// cumulative because HMRC's 10,000-mile threshold is; the rate is the one
  /// in force on the day of the trip, because the IRS changed its 2026 figure
  /// on 1 July and a single figure for the year would understate half of it.
  static Money? _mileage(
    TaxYear year,
    List<MileageJourney> journeys,
    String currency,
  ) {
    if (journeys.isEmpty) return null;

    return MileageCalculator.forJourneys(
      journeys: journeys,
      jurisdiction: year.jurisdiction,
      currency: currency,
    );
  }
}
