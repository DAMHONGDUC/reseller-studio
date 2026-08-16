import 'package:flutter/widgets.dart';
import 'package:system_design/index.dart';

/// Moving a scroll view under program control, on the app's own timing.
///
/// A widget's job is layout, so the arithmetic of "how far is the end and how
/// many passes does a lazy list need to get there" does not live in one —
/// see the extraction rule in `CLAUDE.md`.
final class ScrollUtils {
  /// A lazy sliver only *estimates* its extent from the children built so
  /// far, so one pass lands short of the real end. The second pass runs
  /// against an extent measured with everything built.
  static const int endPasses = 2;

  /// Animate [controller] to the bottom of its content.
  static Future<void> toEnd(ScrollController controller) async {
    for (int pass = 0; pass < endPasses; pass++) {
      if (!controller.hasClients) return;

      final double end = controller.position.maxScrollExtent;

      if (controller.offset >= end) return;

      await controller.animateTo(
        end,
        duration: SdMotionV3.normal,
        curve: SdMotionV3.standard,
      );
    }
  }
}
