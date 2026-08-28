import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/extensions/context_extensions.dart';
import 'package:reseller_studio/features/home/home_constant.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:reseller_studio/features/home/presentation/widgets/flow_overview_sheet.dart';
import 'package:reseller_studio/features/more/workflow_constant.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The sheet that answers "how do I use this app".
///
/// **It is a document, not a menu** — owner's rule: a fixed share of the
/// screen, every step spelled out, and the ones the app never blocks on
/// badged. A step that appears without its instructions is the table of
/// contents this replaced.
void main() {
  Future<BuildContext> openSheet(WidgetTester tester) async {
    await pumpScreen(tester, const HomeScreen());

    final BuildContext context = tester.element(find.byType(HomeScreen));

    await tester.tap(
      find.ancestor(
        of: find.text(
          HomeShortcutLabel.of(context, HomeShortcutKind.flowOverview),
        ),
        matching: find.byType(SdCardV3),
      ),
    );
    await tester.pumpAndSettle();

    return tester.element(find.byType(FlowOverviewSheet));
  }

  testWidgets('the shortcut card opens it', (WidgetTester tester) async {
    await openSheet(tester);

    expect(find.byType(FlowOverviewSheet), findsOneWidget);
  });

  testWidgets(
    'every step is spelled out, and only the skippable ones are badged',
    (WidgetTester tester) async {
      final BuildContext context = await openSheet(tester);
      final Finder scrollable = find.descendant(
        of: find.byType(FlowOverviewSheet),
        matching: find.byType(Scrollable),
      );

      for (final WorkflowStep step in WorkflowConstant.steps) {
        final Finder row = find.byKey(ValueKey<WorkflowKind>(step.kind));

        // Scrolled to, not asserted blind: a sliver only mounts what it
        // shows, so a `find.text` on an unbuilt row fails for the wrong
        // reason.
        await tester.scrollUntilVisible(row, 200, scrollable: scrollable);

        expect(row, findsOneWidget, reason: '${step.kind.name} is missing');

        for (final String line in WorkflowLabel.how(context, step.kind)) {
          expect(
            find.descendant(of: row, matching: find.text(line)),
            findsOneWidget,
            reason: '${step.kind.name} lost an instruction',
          );
        }

        // A badge on a required step tells the seller they may skip something
        // the app will refuse to let them skip.
        expect(
          find.descendant(
            of: row,
            matching: find.text(context.l10n.commonOptional),
          ),
          step.isOptional ? findsOneWidget : findsNothing,
          reason: '${step.kind.name} is badged wrong',
        );
      }
    },
  );

  testWidgets('it takes the share of the screen it asks for', (
    WidgetTester tester,
  ) async {
    await openSheet(tester);

    final double screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(
      tester.getRect(find.byType(FlowOverviewSheet)).height,
      moreOrLessEquals(
        screenHeight * FlowOverviewSheet.heightFactor,
        epsilon: 1,
      ),
    );
  });
}
