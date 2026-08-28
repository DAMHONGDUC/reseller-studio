import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/extensions/context_extensions.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:reseller_studio/features/home/presentation/widgets/flow_overview_sheet.dart';
import 'package:reseller_studio/features/more/workflow_constant.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The sheet that answers "how do I use this app".
///
/// **It is a document, not a menu** — owner's rule: a fixed share of the
/// screen, every step expands to its full instructions, and the ones the app
/// never blocks on are badged.
void main() {
  /// The card sits below the numbers now, so Home has to be scrolled before
  /// it is built — `find` matches built widgets only.
  Future<void> toCard(WidgetTester tester, BuildContext context) async {
    final Finder intro = find.text(context.l10n.flowOverviewIntro);

    for (int i = 0; i < 8 && intro.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
  }

  Future<BuildContext> openSheet(WidgetTester tester) async {
    await pumpScreen(tester, const HomeScreen());

    final BuildContext context = tester.element(find.byType(HomeScreen));

    await toCard(tester, context);
    // Scrolled into view is not the same as tappable: a card half off the
    // bottom edge has its centre outside the viewport.
    await tester.ensureVisible(find.text(context.l10n.flowOverviewIntro));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text(context.l10n.flowOverviewIntro),
        matching: find.byType(SdCardV3),
      ),
    );
    await tester.pumpAndSettle();

    return tester.element(find.byType(FlowOverviewSheet));
  }

  testWidgets('the dedicated Home section opens it', (
    WidgetTester tester,
  ) async {
    await openSheet(tester);

    expect(find.byType(FlowOverviewSheet), findsOneWidget);
  });

  testWidgets('the Home card owns its title and description', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());

    final BuildContext context = tester.element(find.byType(HomeScreen));

    await toCard(tester, context);

    final Finder card = find.ancestor(
      of: find.text(context.l10n.flowOverviewIntro),
      matching: find.byType(SdCardV3),
    );

    expect(card, findsOneWidget);
    expect(
      find.descendant(
        of: card,
        matching: find.text(context.l10n.homeFlowOverview),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text(context.l10n.homeFlowOverview),
        matching: find.byType(SdSectionHeaderV3),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'every step expands independently and only skippable ones are badged',
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
            findsNothing,
            reason: '${step.kind.name} starts expanded',
          );
        }

        await tester.tap(
          find.descendant(
            of: row,
            matching: find.text(WorkflowLabel.title(context, step.kind)),
          ),
        );
        await tester.pumpAndSettle();

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

        await tester.tap(
          find.descendant(
            of: row,
            matching: find.text(WorkflowLabel.title(context, step.kind)),
          ),
        );
        await tester.pumpAndSettle();

        for (final String line in WorkflowLabel.how(context, step.kind)) {
          expect(
            find.descendant(of: row, matching: find.text(line)),
            findsNothing,
            reason: '${step.kind.name} did not collapse',
          );
        }
      }
    },
  );

  testWidgets('it takes the share of the screen it asks for', (
    WidgetTester tester,
  ) async {
    await openSheet(tester);

    final double screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(FlowOverviewSheet.heightFactor, 0.9);
    expect(
      tester.getRect(find.byType(FlowOverviewSheet)).height,
      moreOrLessEquals(
        screenHeight * FlowOverviewSheet.heightFactor,
        epsilon: 1,
      ),
    );
  });
}
