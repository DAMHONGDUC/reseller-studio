import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_design/index.dart';

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

  final String? helperText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => SdTextFieldV3(
    label: label,
    controller: controller,
    hint: '0.00',
    helperText: helperText,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: <TextInputFormatter>[
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
    ],
    textInputAction: textInputAction,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    suffix: Text(
      currency,
      style: context.textTheme3.bodySmall!.faint3(context),
    ),
  );
}
