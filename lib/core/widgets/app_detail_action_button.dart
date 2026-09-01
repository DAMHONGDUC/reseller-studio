import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';

/// The actions control in a detail screen's app bar.
///
/// **A `more_vert` glyph, not a labelled button** — owner's rule, and it is
/// the same control the inventory row already carries. A word in the bar
/// spent the title's width on a label that named no verb: "Actions" says only
/// that there are some, which is exactly what the three dots say in a quarter
/// of the space and in a shape every seller has tapped before.
///
/// The label survives as the tooltip and the semantics label — dropping it
/// would leave a screen reader announcing a button with no name.
class AppDetailActionButton extends StatelessWidget {
  const AppDetailActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// Tooltip and semantics label — never drawn.
  final String label;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(right: SdSpacingConstant.w8),
    child: SdAppBarActionButtonV3(
      icon: AppIconConstant.moreVert,
      tooltip: label,
      onPressed: onPressed,
    ),
  );
}
