import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/extensions/context_extensions.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/features/more/more_constant.dart';
import 'package:reseller_studio/features/more/presentation/screens/about_screen/about_screen.dart';
import 'package:reseller_studio/features/more/workflow_constant.dart';

import '../../support/pump_app.dart';

/// About explains the app, and the workflow it draws is the product's own
/// argument — so the diagram has to stay true to the chain in `CLAUDE.md`
/// rather than drifting into a nice picture.
void main() {
  testWidgets('the app introduces itself before it explains itself', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const AboutScreen());

    final BuildContext context = tester.element(find.byType(AboutScreen));

    expect(find.text(context.l10n.aboutTagline), findsOneWidget);
    expect(find.text(context.l10n.aboutIntro), findsOneWidget);
    expect(find.text(context.l10n.aboutPrinciple), findsOneWidget);
  });

  testWidgets('every step of the workflow is drawn', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const AboutScreen());

    final BuildContext context = tester.element(find.byType(AboutScreen));

    for (final WorkflowStep step in WorkflowConstant.steps) {
      // Scrolled between checks: nine steps do not fit on one screen, and a
      // diagram whose tail never builds is one nobody has actually seen.
      await tester.scrollUntilVisible(
        find.text(WorkflowLabel.title(context, step.kind)),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        find.text(WorkflowLabel.title(context, step.kind)),
        findsOneWidget,
        reason: '${step.kind.name} is missing from the diagram',
      );
    }
  });

  test('the diagram matches the lifecycle, in order', () {
    // The chain `CLAUDE.md` writes as one line. Order is the whole meaning
    // here — a diagram that lists the same nine steps shuffled says something
    // different and still looks fine.
    expect(
      WorkflowConstant.steps.map((WorkflowStep step) => step.kind).toList(),
      <WorkflowKind>[
        WorkflowKind.source,
        WorkflowKind.purchase,
        WorkflowKind.inventory,
        WorkflowKind.list,
        WorkflowKind.sell,
        WorkflowKind.ship,
        WorkflowKind.profit,
        WorkflowKind.analyze,
        WorkflowKind.sourceBetter,
      ],
    );
  });

  test('every step opens somewhere real', () {
    for (final WorkflowStep step in WorkflowConstant.steps) {
      expect(step.route, startsWith('/'));
      // A parameterised path cannot be pushed without its argument, so no
      // step may point at one — the diagram is a way in, and a dead link in
      // it is worse than no link.
      expect(
        step.route,
        isNot(contains(':')),
        reason: '${step.kind.name} points at a parameterised route',
      );
    }
  });

  test('About sits in More, directly below Settings', () {
    // Owner's call, reversing the old home in Settings.
    final List<String> routes = MoreConstant.destinations
        .map((MoreDestination d) => d.route)
        .toList();

    expect(
      routes.indexOf(AppRoutes.about),
      routes.indexOf(AppRoutes.settings) + 1,
    );
  });
}
