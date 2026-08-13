import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/core/money/money.dart';
import 'package:seller_os/features/expenses/domain/entities/expense.dart';
import 'package:seller_os/features/listings/domain/enums/listing_status.dart';
import 'package:seller_os/features/marketplaces/domain/enums/marketplace.dart';
import 'package:seller_os/features/orders/domain/entities/order.dart';
import 'package:seller_os/features/orders/domain/enums/order_status.dart';
import 'package:seller_os/features/tax/domain/entities/tax_summary.dart';
import 'package:seller_os/features/tax/domain/entities/tax_year.dart';
import 'package:seller_os/features/tax/domain/enums/tax_jurisdiction.dart';
import 'package:seller_os/features/tax/domain/services/tax_summary_calculator.dart';

/// Rows are placed against a tax-year boundary on purpose: the only thing
/// worth testing here is what falls in and what falls out.
void main() {
  const TaxYear uk2026 = TaxYear(
    jurisdiction: TaxJurisdiction.uk,
    startingYear: 2026,
  );

  Order order(DateTime when, int saleMinor, int? costMinor) => Order(
    id: 'ord-${when.millisecondsSinceEpoch}',
    status: OrderStatus.delivered,
    marketplace: Marketplace.ebay,
    lines: <OrderLine>[
      OrderLine(
        itemId: 'itm-1',
        title: 'A jacket',
        quantity: 1,
        unitPrice: Money(saleMinor, 'GBP'),
        unitCost: costMinor == null ? null : Money(costMinor, 'GBP'),
      ),
    ],
    salePrice: Money(saleMinor, 'GBP'),
    orderedAt: when,
  );

  Expense expense(
    DateTime when,
    ExpenseCategory category,
    int minor, {
    double? miles,
  }) => Expense(
    id: 'exp-${when.millisecondsSinceEpoch}-${category.name}',
    category: category,
    amount: Money(minor, 'GBP'),
    date: when,
    createdAt: when,
    mileage: miles,
  );

  group('what falls inside the year', () {
    test('a sale on 5 April belongs to the previous UK year', () {
      final TaxSummary summary = TaxSummaryCalculator.of(
        year: uk2026,
        orders: <Order>[
          // One day before the year opens, and one day after.
          order(DateTime(2026, DateTime.april, 5), 10000, 4000),
          order(DateTime(2026, DateTime.april, 7), 25000, 9000),
        ],
        expenses: const <Expense>[],
        currency: 'GBP',
      );

      expect(summary.revenue, const Money(25000, 'GBP'));
      expect(summary.costOfGoods, const Money(9000, 'GBP'));
    });

    test('the last instant of the year is still in it', () {
      final TaxSummary summary = TaxSummaryCalculator.of(
        year: uk2026,
        orders: <Order>[
          order(
            uk2026.endExclusive.subtract(const Duration(milliseconds: 1)),
            5000,
            null,
          ),
        ],
        expenses: const <Expense>[],
        currency: 'GBP',
      );

      expect(summary.revenue, const Money(5000, 'GBP'));
    });
  });

  group('expenses group into the jurisdiction lines', () {
    test('UK lines are named after SA103, not Schedule C', () {
      final TaxSummary summary = TaxSummaryCalculator.of(
        year: uk2026,
        orders: const <Order>[],
        expenses: <Expense>[
          expense(
            DateTime(2026, DateTime.june),
            ExpenseCategory.storage,
            12000,
          ),
        ],
        currency: 'GBP',
      );

      final TaxLineTotal rent = summary.lines.firstWhere(
        (TaxLineTotal line) => line.line.startsWith('Rent'),
      );

      expect(rent.line, 'Rent, rates, power and insurance');
      expect(rent.amount, const Money(12000, 'GBP'));
    });

    test('a line with nothing against it is null, never zero', () {
      final TaxSummary summary = TaxSummaryCalculator.of(
        year: uk2026,
        orders: const <Order>[],
        expenses: const <Expense>[],
        currency: 'GBP',
      );

      // Hard rule 5: the line is still listed so it can be ticked off, but
      // its amount is unknown rather than a claim that nothing was spent.
      expect(summary.lines, isNotEmpty);
      expect(
        summary.lines.every((TaxLineTotal line) => line.amount == null),
        isTrue,
      );
    });
  });

  group('mileage', () {
    test('is deducted at the rate, not at what was spent', () {
      final TaxSummary summary = TaxSummaryCalculator.of(
        year: uk2026,
        orders: const <Order>[],
        expenses: <Expense>[
          // £40 of fuel recorded against 200 miles. The deduction is
          // 200 × 45p = £90, and the £40 must not also appear on a line.
          expense(
            DateTime(2026, DateTime.june),
            ExpenseCategory.mileage,
            4000,
            miles: 200,
          ),
        ],
        currency: 'GBP',
      );

      expect(summary.mileageDistance, 200);
      expect(summary.mileageDeduction, const Money(9000, 'GBP'));

      // The recorded amount is not double-counted into the car line.
      final TaxLineTotal car = summary.lines.firstWhere(
        (TaxLineTotal line) => line.line.startsWith('Car'),
      );

      expect(car.amount, isNull);
    });

    test('bands apply over the year, so a big year splits', () {
      final TaxSummary summary = TaxSummaryCalculator.of(
        year: uk2026,
        orders: const <Order>[],
        expenses: <Expense>[
          expense(
            DateTime(2026, DateTime.may),
            ExpenseCategory.mileage,
            0,
            miles: 6000,
          ),
          expense(
            DateTime(2026, DateTime.july),
            ExpenseCategory.mileage,
            0,
            miles: 6000,
          ),
        ],
        currency: 'GBP',
      );

      // 12,000 miles across two trips: 10,000 × 45p + 2,000 × 25p. Rating
      // each trip on its own would give 12,000 × 45p and over-deduct.
      expect(summary.mileageDistance, 12000);
      expect(summary.mileageDeduction, const Money(500000, 'GBP'));
    });
  });

  test('net is revenue less cost of goods less deductions', () {
    final TaxSummary summary = TaxSummaryCalculator.of(
      year: uk2026,
      orders: <Order>[order(DateTime(2026, DateTime.june), 100000, 30000)],
      expenses: <Expense>[
        expense(DateTime(2026, DateTime.june), ExpenseCategory.storage, 10000),
      ],
      currency: 'GBP',
    );

    // 100000 - 30000 - 10000
    expect(summary.netBeforeTax, const Money(60000, 'GBP'));
  });
}
