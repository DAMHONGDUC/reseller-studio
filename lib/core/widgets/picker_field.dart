import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';

/// A form row whose value is chosen from a sheet rather than typed.
///
/// Looks like `SdTextFieldV3` on purpose — a form where half the rows are
/// boxes and half are list tiles reads as two forms. It is not a text field,
/// though: there is nothing to type, so it takes a tap and shows what is
/// currently set.
///
/// [value] of null renders [placeholder] in the muted colour, which is how a
/// seller tells "not chosen" from "chosen and happens to be short".
class PickerField extends StatelessWidget {
  const PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder,
    this.icon,
    super.key,
  });

  final String label;
  final String? value;
  /// Null falls back to the shared "Not set" label. A parameter default
  /// cannot be a localized string — it is evaluated with no `BuildContext`.
  final String? placeholder;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;
    final String empty = placeholder ?? context.l10n.actionNotSet;

    return Semantics(
      button: true,
      label: label,
      value: value ?? empty,
      child: InkWell(
        onTap: onTap,
        borderRadius: SdRadiusV3.inputAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: context.textTheme3.labelMedium!.muted3(context)),
            SizedBox(height: SdSpacingConstant.h6),
            Container(
              height: SdSpacingConstant.h48,
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              decoration: BoxDecoration(
                color: context.sdTheme3.surfaceSunken,
                borderRadius: SdRadiusV3.inputAll,
                border: Border.all(color: context.sdTheme3.border),
              ),
              child: Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    SdIconV3(
                      icon!,
                      size: SdIconV3.smallSize,
                      color: context.sdTheme3.textSecondary,
                    ),
                    SizedBox(width: SdSpacingConstant.w8),
                  ],
                  Expanded(
                    child: Text(
                      value ?? empty,
                      overflow: TextOverflow.ellipsis,
                      style: hasValue
                          ? context.textTheme3.bodyMedium!.copyWith(
                              color: context.sdTheme3.textPrimary,
                            )
                          : context.textTheme3.bodyMedium!.faint3(context),
                    ),
                  ),
                  SdIconV3(
                    Symbols.expand_more_rounded,
                    size: SdIconV3.smallSize,
                    color: context.sdTheme3.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
