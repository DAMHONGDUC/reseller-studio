import '../../../listings/domain/enums/listing_status.dart';
import '../enums/tax_jurisdiction.dart';

/// What a cost is called on the seller's own return (plan §20).
///
/// **The app's `ExpenseCategory` is the seller's vocabulary; this is the tax
/// authority's.** They are deliberately separate: "packaging" is how a
/// reseller thinks and files under a different line in each country, and
/// merging the two would mean renaming the app's categories every time a
/// jurisdiction is added.
///
/// The mapping is a **starting point, not advice**. Nothing here decides what
/// a seller may deduct; it groups their own records into the lines their form
/// asks for, and the screen says so.
class TaxCategory {
  const TaxCategory({required this.line, required this.expenses});

  /// The line as the form names it — a Schedule C line in the US, a
  /// self-assessment box in the UK.
  final String line;

  final List<ExpenseCategory> expenses;
}

/// The per-jurisdiction mapping, in one place.
///
/// Adding a country means adding a case here and a mileage rate. Nothing else
/// in the feature changes — that is what `CLAUDE.md`'s "a third jurisdiction
/// is data" rule buys.
final class TaxCategoryConstant {
  static List<TaxCategory> of(TaxJurisdiction jurisdiction) =>
      switch (jurisdiction) {
        TaxJurisdiction.us => _us,
        TaxJurisdiction.uk => _uk,
      };

  /// US — Schedule C (Form 1040), Part II.
  static const List<TaxCategory> _us = <TaxCategory>[
    TaxCategory(
      line: 'Advertising',
      expenses: <ExpenseCategory>[ExpenseCategory.advertising],
    ),
    TaxCategory(
      line: 'Car and truck expenses',
      expenses: <ExpenseCategory>[ExpenseCategory.mileage],
    ),
    TaxCategory(
      line: 'Office expense',
      expenses: <ExpenseCategory>[
        ExpenseCategory.packaging,
        ExpenseCategory.software,
      ],
    ),
    TaxCategory(
      line: 'Rent or lease',
      expenses: <ExpenseCategory>[ExpenseCategory.storage],
    ),
    TaxCategory(
      line: 'Repairs and maintenance',
      expenses: <ExpenseCategory>[ExpenseCategory.repairs],
    ),
    TaxCategory(
      line: 'Supplies',
      expenses: <ExpenseCategory>[ExpenseCategory.equipment],
    ),
    TaxCategory(
      line: 'Other expenses',
      expenses: <ExpenseCategory>[
        ExpenseCategory.shipping,
        ExpenseCategory.other,
      ],
    ),
  ];

  /// UK — self-assessment SA103 (self-employment).
  static const List<TaxCategory> _uk = <TaxCategory>[
    TaxCategory(
      line: 'Advertising and business entertainment',
      expenses: <ExpenseCategory>[ExpenseCategory.advertising],
    ),
    TaxCategory(
      line: 'Car, van and travel expenses',
      expenses: <ExpenseCategory>[ExpenseCategory.mileage],
    ),
    TaxCategory(
      line: 'Cost of goods bought for resale',
      expenses: <ExpenseCategory>[],
    ),
    TaxCategory(
      line: 'Office costs',
      expenses: <ExpenseCategory>[
        ExpenseCategory.packaging,
        ExpenseCategory.software,
      ],
    ),
    TaxCategory(
      line: 'Rent, rates, power and insurance',
      expenses: <ExpenseCategory>[ExpenseCategory.storage],
    ),
    TaxCategory(
      line: 'Repairs and renewals',
      expenses: <ExpenseCategory>[
        ExpenseCategory.repairs,
        ExpenseCategory.equipment,
      ],
    ),
    TaxCategory(
      line: 'Other business expenses',
      expenses: <ExpenseCategory>[
        ExpenseCategory.shipping,
        ExpenseCategory.other,
      ],
    ),
  ];
}
