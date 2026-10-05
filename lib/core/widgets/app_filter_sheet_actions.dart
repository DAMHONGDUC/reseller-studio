import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';

/// The footer of a filter sheet: Reset beside Apply.
///
/// - **Reset empties the draft and applies nothing** — Apply is still what
///   writes it to the screen (`docs/rules/SCREENS.md`)
/// - Reset is disabled while [pending] is zero: there is nothing to reset
class AppFilterSheetActions extends StatelessWidget {
  const AppFilterSheetActions({
    required this.pending,
    required this.onReset,
    required this.onApply,
    super.key,
  });

  /// How many groups the draft is narrowing, counted the way the strip's bar
  /// counts them.
  final int pending;

  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: SdButtonV3(
          variant: SdButtonVariantV3.outlined,
          expand: true,
          label: context.l10n.filterReset,
          onPressed: pending == 0 ? null : onReset,
        ),
      ),
      SizedBox(width: SdSpacingConstant.w12),
      Expanded(
        child: SdButtonV3(
          variant: SdButtonVariantV3.primary,
          expand: true,
          label: context.l10n.filterApply,
          onPressed: onApply,
        ),
      ),
    ],
  );
}
