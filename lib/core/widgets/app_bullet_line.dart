import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// One instruction in a list of steps: a small dot, then the line.
///
/// Home's flow overview and About's guide both draw how-to lines, so the dot
/// is one widget rather than two that drift apart.
class AppBulletLine extends StatelessWidget {
  const AppBulletLine({required this.text, super.key});

  final String text;

  /// The marker's own size and the space it is centred in.
  static double get dotSize => SdSpacingConstant.r4;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      ExcludeSemantics(
        child: Container(
          width: dotSize,
          height: dotSize,
          // Lines the dot up with the middle of the first line of text
          // rather than with the top of its box.
          margin: EdgeInsets.only(top: SdSpacingConstant.h8),
          decoration: BoxDecoration(
            color: context.sdTheme3.textTertiary,
            shape: BoxShape.circle,
          ),
        ),
      ),
      SizedBox(width: SdSpacingConstant.w8),
      Expanded(
        child: Text(
          text,
          style: context.textTheme3.bodySmall!.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
      ),
    ],
  );
}
