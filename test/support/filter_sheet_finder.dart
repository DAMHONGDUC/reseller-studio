import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_filter_sheet_actions.dart';
import 'package:system_design/index.dart';

/// Finds the buttons in a filter sheet's footer.
///
/// The strip behind the sheet has a Reset of its own, so `find.text('Reset')`
/// alone matches two.
final class FilterSheetFinder {
  static Finder reset() => find.descendant(
    of: find.byType(AppFilterSheetActions),
    matching: find.text('Reset'),
  );

  /// Whether the footer's Reset can be pressed.
  static bool resetEnabled(WidgetTester tester) =>
      tester
          .widget<SdButtonV3>(
            find.ancestor(of: reset(), matching: find.byType(SdButtonV3)),
          )
          .onPressed !=
      null;
}
