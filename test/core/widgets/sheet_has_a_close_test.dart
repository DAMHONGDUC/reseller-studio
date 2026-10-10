import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **Every sheet carries a close icon, and the chrome draws it** — owner's
/// rule, in `docs/rules/DESIGN_SYSTEM.md`.
///
/// The grab handle and the barrier tap are conventions a seller has to
/// already know; the button is the exit that has to be taught to nobody. It
/// lives in `SdBottomSheetV3` so no sheet can be written without one, and
/// these tests pin both halves: the chrome draws it and it closes the route,
/// and no call site draws a second one inside its content.
void main() {
  testWidgets('the chrome draws a close button that pops the sheet', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showSdBottomSheetV3<void>(
              context: context,
              builder: (BuildContext _) => const SdBottomSheetV3(
                title: 'Sheet',
                closeTooltip: 'Close',
                child: Text('sheet body', style: TextStyle()),
              ),
            ),
            child: const Text('open', style: TextStyle()),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('sheet body'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('sheet body'), findsNothing);
  });

  test('no sheet draws its own close', () {
    // Source rather than a pumped tree: the rule is about every call site,
    // and pumping the sheets that happen to have tests would check a fraction
    // of them and call it all.
    final List<String> offenders = <String>[];

    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final String source = entity.readAsStringSync();

      if (source.contains('SdBottomSheetV3(') &&
          source.contains('Icons.close')) {
        offenders.add(entity.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these sheets draw a close of their own — `SdBottomSheetV3` already '
          'puts one on the title row:\n${offenders.join('\n')}',
    );
  });
}
