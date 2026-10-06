import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_filter_sheet_actions.dart';
import 'package:reseller_studio/core/widgets/app_filter_strip.dart';
import 'package:system_design/index.dart';

/// Finds the buttons in a filter sheet's footer, and the chips on the strip
/// that open one.
///
/// The strip behind the sheet has a Reset of its own, so `find.text('Reset')`
/// alone matches two.
final class FilterSheetFinder {
  /// The strip's chip labelled [label] — never the sheet's chip of the same
  /// name.
  static Finder stripChip(String label) => find.descendant(
    of: find.byType(AppFilterStrip),
    matching: find.widgetWithText(SdFilterChipV3, label),
  );

  /// Whether the strip's chip labelled [label] is drawn selected.
  static bool stripChipSelected(WidgetTester tester, String label) =>
      tester.widget<SdFilterChipV3>(stripChip(label)).selected;

  /// Scrolls the strip to [label]'s chip and taps it — the chips run past a
  /// phone's width.
  static Future<void> tapStripChip(WidgetTester tester, String label) async {
    await tester.ensureVisible(stripChip(label));
    await tester.pumpAndSettle();
    await tester.tap(stripChip(label));
    await tester.pumpAndSettle();
  }

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
