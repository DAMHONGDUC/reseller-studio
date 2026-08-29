import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/currency_decimals.dart';
import 'package:reseller_studio/core/money/money.dart';

/// **A đồng has no cents, and getting that wrong is a factor-of-100 error in
/// every figure the app shows a Vietnamese seller.** These are the tests that
/// stop the 2-decimal assumption creeping back in.
void main() {
  group('CurrencyDecimals', () {
    test('a currency with cents reports two places', () {
      expect(CurrencyDecimals.of('USD'), 2);
      expect(CurrencyDecimals.factorFor('USD'), 100);
    });

    test('a currency with no minor unit reports none', () {
      expect(CurrencyDecimals.of('VND'), 0);
      expect(CurrencyDecimals.factorFor('VND'), 1);
      expect(CurrencyDecimals.of('JPY'), 0);
    });

    test('a three-decimal dinar reports three, not the fallback two', () {
      // These were left out while the picker offered nine currencies. It now
      // offers every one, so a Kuwaiti business would have had every amount
      // out by a factor of ten.
      expect(CurrencyDecimals.of('KWD'), 3);
      expect(CurrencyDecimals.factorFor('KWD'), 1000);

      for (final String code in <String>[
        'BHD',
        'IQD',
        'JOD',
        'LYD',
        'OMR',
        'TND',
      ]) {
        expect(CurrencyDecimals.of(code), 3, reason: code);
      }
    });

    test('the code is matched case-insensitively', () {
      expect(CurrencyDecimals.of('vnd'), 0);
    });

    test('an unknown code falls back to two rather than guessing', () {
      // Under-reporting a zero-decimal currency is recoverable; inflating one
      // by a hundred is the error a seller never forgives.
      expect(CurrencyDecimals.of('ZZZ'), CurrencyDecimals.fallback);
    });
  });

  group('Money parses in the currency it was given', () {
    test('19.99 in USD is 1999 minor units', () {
      expect(Money.tryParse('19.99', 'USD'), const Money(1999, 'USD'));
    });

    test('450000 in VND is 450000 minor units, not 45 million', () {
      expect(Money.tryParse('450000', 'VND'), const Money(450000, 'VND'));
    });

    test('an empty box is not known, and is never zero', () {
      // Hard rule 4: null means nobody entered it. Money.zero would claim the
      // item was free.
      expect(Money.tryParse('', 'USD'), isNull);
      expect(Money.tryParse('   ', 'VND'), isNull);
    });

    test('thousands separators a human typed are ignored', () {
      expect(Money.tryParse('1,234.50', 'USD'), const Money(123450, 'USD'));
    });

    test('a price that rounds badly in binary still lands on the cent', () {
      // 19.99 arrives as 19.989999…; toInt would truncate it to 1998.
      expect(Money.tryParse('19.99', 'USD')!.minor, 1999);
      expect(Money.tryParse('0.07', 'USD')!.minor, 7);
    });
  });

  group('Money renders back into a field', () {
    test('a USD amount round-trips through the input string', () {
      const Money amount = Money(1999, 'USD');

      expect(amount.toInputString(), '19.99');
      expect(Money.tryParse(amount.toInputString(), 'USD'), amount);
    });

    test('a KWD amount round-trips with three decimal places', () {
      const Money amount = Money(19990, 'KWD');

      expect(amount.toInputString(), '19.990');
      expect(Money.tryParse(amount.toInputString(), 'KWD'), amount);
    });

    test('a VND amount round-trips with no decimal point', () {
      const Money amount = Money(450000, 'VND');

      expect(amount.toInputString(), '450,000');
      expect(Money.tryParse(amount.toInputString(), 'VND'), amount);
    });

    test('major units divide by the currency factor, not always 100', () {
      expect(const Money(1999, 'USD').major, 19.99);
      expect(const Money(450000, 'VND').major, 450000);
    });
  });
}
