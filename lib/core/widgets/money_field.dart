import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../money/currency_decimals.dart';
import '../money/currency_input_formatter.dart';

/// A field that takes an amount of money.
///
/// **An empty box stays empty and means "not known".** It never becomes zero
/// (hard rule 4) — the caller parses with `Money.tryParse`, which returns null
/// for an empty string, and a null cost renders `—` everywhere downstream
/// rather than claiming the item was free.
///
/// The keyboard is numeric with a decimal point, and the formatter refuses
/// letters outright: a seller typing a price one-handed in a shop should not
/// be able to produce a value the parser will silently drop.
class MoneyField extends StatelessWidget {
  const MoneyField({
    required this.label,
    required this.controller,
    required this.currency,
    this.isRequired = false,
    this.errorText,
    this.helperText,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;

  /// Shown as the field's prefix, so the seller can see which currency they
  /// are typing in without reading the workspace settings.
  final String currency;

  /// Passed straight through to the field's label marker.
  final bool isRequired;

  /// Tints the border and replaces [helperText] below the field. A form that
  /// can only report a problem in a snackbar makes the seller guess which box
  /// it meant.
  final String? errorText;

  final String? helperText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// `0.00` where there are cents, `0` where there are not — the hint is the
  /// only thing telling a seller in đồng that this box does not want decimals.
  String get _hint => CurrencyDecimals.of(currency) == 0
      ? '0'
      : '0.${'0' * CurrencyDecimals.of(currency)}';

  @override
  Widget build(BuildContext context) => SdTextFieldV3(
    label: label,
    controller: controller,
    hint: _hint,
    isRequired: isRequired,
    errorText: errorText,
    helperText: helperText,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: <CurrencyInputFormatter>[CurrencyInputFormatter(currency)],
    textInputAction: textInputAction,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    suffix: Text(
      currency,
      style: context.textTheme3.bodySmall!.faint3(context),
    ),
  );
}
