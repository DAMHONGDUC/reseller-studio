import 'dart:ui';

import '../constants/scanner_constant.dart';

/// Where the scanner's frame sits in the camera view.
final class ScannerFrameUtils {
  /// Centred, sized off the shorter side so a tablet in landscape does not
  /// get a frame wider than the code it is meant to hold.
  static Rect rect(Size size) {
    final double width = size.shortestSide * ScannerConstant.windowWidthFactor;

    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: width / ScannerConstant.windowAspectRatio,
    );
  }
}
