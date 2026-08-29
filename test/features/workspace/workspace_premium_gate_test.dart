import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/widgets/workspace_switcher_sheet.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';
import 'package:reseller_studio/features/subscription/providers.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('the business ceiling opens the Premium gate before its form', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const _OpenSwitcher(),
      overrides: <Override>[
        addWorkspaceBlockProvider.overrideWith(
          (Ref ref) => PlanBlock.workspaceLimit,
        ),
      ],
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new business'));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to continue'), findsOneWidget);
    expect(find.textContaining('business. Upgrade'), findsOneWidget);
  });
}

class _OpenSwitcher extends StatelessWidget {
  const _OpenSwitcher();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => WorkspaceSwitcherSheet.show(context),
        child: const Text('Open'),
      ),
    ),
  );
}
