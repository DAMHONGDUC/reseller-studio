import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// Two stat cards that always share the taller card's height.
class AppStatTileRow extends StatelessWidget {
  const AppStatTileRow({required this.left, required this.right, super.key});

  final SdStatTileV3 left;
  final SdStatTileV3 right;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: left),
        SizedBox(width: SdSpacingConstant.w8),
        Expanded(child: right),
      ],
    ),
  );
}
