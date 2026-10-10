import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';

/// The line under a filter strip that says how narrowed the list is, and
/// offers the one control that undoes it.
///
/// **A filter a seller cannot see is a list that looks broken.** Inventory and
/// Orders both hide their extra filters behind a sheet, so without this row an
/// item missing from the list and an item filtered out of it look identical —
/// and the seller's fix is to hunt through a sheet for the chip they forgot.
///
/// In `core/widgets/` because both tabs render it. The filter sheets do not:
/// their Reset is `AppFilterSheetActions`, beside Apply.
class AppActiveFilterBar extends StatelessWidget {
  const AppActiveFilterBar({
    required this.count,
    required this.onReset,
    super.key,
  });

  /// How many filters are narrowing the list. **Zero renders nothing** — a row
  /// saying "0 filters" is chrome describing the absence of chrome.
  final int count;

  final VoidCallback onReset;

  /// The band this occupies, stated so Inventory's pinned sliver can give its
  /// extent before it lays anything out — the same reason
  /// `SdFilterChipV3.height` exists.
  static double get height => SdSpacingConstant.h40;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV3.horizontal,
        ),
        child: Row(
          children: <Widget>[
            SdIconV3(
              AppIconConstant.tune,
              size: SdSpacingConstant.w16,
              color: context.sdTheme3.textSecondary,
            ),
            SizedBox(width: SdSpacingConstant.w8),
            Expanded(
              child: Text(
                context.l10n.filterAppliedCount(count),
                style: context.textTheme3.bodySmall!.muted3(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SdButtonV3(
              variant: SdButtonVariantV3.text,
              size: SdButtonSizeV3.small,
              icon: AppIconConstant.filterAltOff,
              label: context.l10n.filterReset,
              onPressed: onReset,
            ),
          ],
        ),
      ),
    );
  }
}
