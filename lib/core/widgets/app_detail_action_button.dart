import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';

/// The labelled actions control in a detail screen's app bar.
///
/// Medium proportions keep the icon and `labelLarge` text at the same visual
/// weight. The wrapper also owns the app bar's trailing inset for every detail.
class AppDetailActionButton extends StatelessWidget {
  const AppDetailActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(right: SdSpacingConstant.w8),
    child: SdButtonV3(
      variant: SdButtonVariantV3.secondary,
      size: SdButtonSizeV3.medium,
      label: label,
      icon: AppIconConstant.tune,
      onPressed: onPressed,
    ),
  );
}
