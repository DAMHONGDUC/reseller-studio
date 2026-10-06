import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/scanner_constant.dart';
import 'package:reseller_studio/core/utils/scanner_frame_utils.dart';

/// The frame the scanner reads inside: centred, wider than tall, and sized
/// off the shorter side so landscape does not stretch it.
void main() {
  test('is centred and wider than tall on a phone', () {
    const Size phone = Size(393, 700);
    final Rect frame = ScannerFrameUtils.rect(phone);

    expect(frame.center.dx, closeTo(phone.width / 2, 0.0001));
    expect(frame.center.dy, closeTo(phone.height / 2, 0.0001));
    expect(frame.width, closeTo(393 * ScannerConstant.windowWidthFactor, 0.01));
    expect(
      frame.width / frame.height,
      closeTo(ScannerConstant.windowAspectRatio, 0.0001),
    );
  });

  test('takes the shorter side in landscape', () {
    expect(
      ScannerFrameUtils.rect(const Size(1180, 700)).width,
      closeTo(700 * ScannerConstant.windowWidthFactor, 0.01),
    );
  });
}
