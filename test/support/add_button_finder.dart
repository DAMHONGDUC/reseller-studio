import 'package:flutter_test/flutter_test.dart';
import 'package:system_design/index.dart';

/// Finds a screen's add button by what it does.
///
/// The button is a `+` with no title, so its words exist only as the
/// semantics label — `find.text` cannot see them.
final class AddButtonFinder {
  static Finder named(String label) => find.descendant(
    of: find.byType(SdFabV3),
    matching: find.bySemanticsLabel(label),
  );
}
