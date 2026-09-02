import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/orders/domain/services/bundle_allocation.dart';

/// One payment, several lines.
///
/// The buyer paid one number and nothing in the world says which part of it
/// was the jacket, so the split is a judgement — but it has to be a judgement
/// that adds up. An order whose lines do not sum to what the buyer paid is a
/// reconciliation nobody can close.
void main() {
  const String gbp = 'GBP';

  Money gbpOf(int minor) => Money(minor, gbp);

  int sumOf(List<Money> parts) =>
      parts.fold(0, (int running, Money part) => running + part.minor);

  test('splits by expected price when every item has one', () {
    // A £45 jacket and a £15 shirt sold together for £48: the seller's own
    // proportion, 3:1.
    final List<Money> parts = BundleAllocation.across(gbpOf(4800), <Money?>[
      gbpOf(4500),
      gbpOf(1500),
    ]);

    expect(parts, <Money>[gbpOf(3600), gbpOf(1200)]);
    expect(sumOf(parts), 4800);
  });

  test('splits evenly when any item has no expected price', () {
    // Weighting only the priced one would load the whole bundle onto it and
    // report the other as nearly free.
    final List<Money> parts = BundleAllocation.across(gbpOf(4800), <Money?>[
      gbpOf(4500),
      null,
    ]);

    expect(parts, <Money>[gbpOf(2400), gbpOf(2400)]);
  });

  test('the parts always add up to what the buyer paid', () {
    // £10 across three: 333 + 333 + 333 leaves a penny, and dropping it is a
    // sale that does not reconcile.
    final List<Money> parts = BundleAllocation.across(gbpOf(1000), <Money?>[
      null,
      null,
      null,
    ]);

    expect(sumOf(parts), 1000);
    expect(parts.map((Money p) => p.minor), containsAll(<int>[334, 333]));
  });

  test('a proportional split settles its remainder too', () {
    final List<Money> parts = BundleAllocation.across(gbpOf(1000), <Money?>[
      gbpOf(100),
      gbpOf(100),
      gbpOf(100),
    ]);

    expect(sumOf(parts), 1000);
  });

  test('the rounding penny lands on the largest part', () {
    // Invisible on the biggest line; on the smallest it can be a measurable
    // share of it.
    final List<Money> parts = BundleAllocation.across(gbpOf(1001), <Money?>[
      gbpOf(9000),
      gbpOf(1000),
    ]);

    expect(sumOf(parts), 1001);
    expect(parts.first.minor, greaterThan(parts.last.minor));
  });

  test('one item takes the whole price, untouched', () {
    // The single-sale path is the same call, and it must not round anything.
    expect(
      BundleAllocation.across(gbpOf(4999), <Money?>[null]),
      <Money>[gbpOf(4999)],
    );
  });

  test('nothing to split is an empty answer, not a crash', () {
    expect(BundleAllocation.across(gbpOf(1000), const <Money?>[]), isEmpty);
  });

  test('expected prices that sum to nothing fall back to an even split', () {
    // Two items both recorded at zero cannot weight anything.
    final List<Money> parts = BundleAllocation.across(gbpOf(1000), <Money?>[
      gbpOf(0),
      gbpOf(0),
    ]);

    expect(parts, <Money>[gbpOf(500), gbpOf(500)]);
  });
}
