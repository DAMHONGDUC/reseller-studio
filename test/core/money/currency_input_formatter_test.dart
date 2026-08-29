import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/currency_input_formatter.dart';
import 'package:reseller_studio/core/money/money.dart';

void main() {
  test('groups thousands while preserving cents and the cursor', () {
    final CurrencyInputFormatter formatter = CurrencyInputFormatter('USD');

    final TextEditingValue value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '1234567.89',
        selection: TextSelection.collapsed(offset: 10),
      ),
    );

    expect(value.text, '1,234,567.89');
    expect(value.selection, const TextSelection.collapsed(offset: 12));
  });

  test('limits decimals to the currency precision', () {
    final CurrencyInputFormatter formatter = CurrencyInputFormatter('USD');

    final TextEditingValue value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '1234.567',
        selection: TextSelection.collapsed(offset: 8),
      ),
    );

    expect(value.text, '1,234.56');
    expect(Money.tryParse(value.text, 'USD'), const Money(123456, 'USD'));
  });

  test('zero-decimal currencies reject a decimal part', () {
    final CurrencyInputFormatter formatter = CurrencyInputFormatter('VND');

    final TextEditingValue value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '450000.25',
        selection: TextSelection.collapsed(offset: 9),
      ),
    );

    expect(value.text, '450,000');
    expect(Money.tryParse(value.text, 'VND'), const Money(450000, 'VND'));
  });

  test('existing money is formatted before an edit begins', () {
    expect(const Money(123456789, 'USD').toInputString(), '1,234,567.89');
    expect(const Money(450000, 'VND').toInputString(), '450,000');
  });
}
