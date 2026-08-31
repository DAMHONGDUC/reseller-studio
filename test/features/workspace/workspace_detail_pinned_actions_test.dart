import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/workspace/presentation/screens/workspace_detail_screen/workspace_detail_screen.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

import '../../support/pump_app.dart';

/// Business details is the record it edits, so both of its verbs are the
/// screen's — `docs/rules/SCREENS.md`. Delete used to scroll off the end of
/// the form.
void main() {
  /// The delete button is owner-only, and the mock container resolves no
  /// membership role — so the permission is the one thing stubbed here.
  Future<void> pumpAsOwner(WidgetTester tester) => pumpScreen(
    tester,
    const WorkspaceDetailScreen(workspaceId: 'ws-demo'),
    overrides: <Override>[canDeleteWorkspaceProvider.overrideWithValue(true)],
  );

  testWidgets('save and delete are both out of the scroll', (
    WidgetTester tester,
  ) async {
    await pumpAsOwner(tester);

    for (final String label in <String>['Save', 'Delete this business']) {
      expect(find.text(label), findsOneWidget);
      expect(
        find.ancestor(of: find.text(label), matching: find.byType(Scrollable)),
        findsNothing,
        reason: '$label holds the bottom edge',
      );
    }
  });

  testWidgets('the primary sits lowest, so the thumb never rests on delete', (
    WidgetTester tester,
  ) async {
    await pumpAsOwner(tester);

    expect(
      tester.getRect(find.text('Delete this business')).bottom,
      lessThan(tester.getRect(find.text('Save')).top),
    );
  });

  testWidgets('a seller who cannot delete gets save alone, flush to the foot', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const WorkspaceDetailScreen(workspaceId: 'ws-demo'),
    );

    // The conditional button carries its own gap, so its absence leaves no
    // hole above Save.
    expect(find.text('Delete this business'), findsNothing);
    expect(find.text('Save'), findsOneWidget);
  });
}
