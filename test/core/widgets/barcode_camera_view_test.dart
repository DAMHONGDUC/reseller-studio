import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:reseller_studio/core/permissions/app_permission.dart';
import 'package:reseller_studio/core/providers/system_permissions_provider.dart';
import 'package:reseller_studio/core/widgets/barcode_camera_view.dart';

import '../../support/fakes/fake_scanner_platform.dart';
import '../../support/fakes/fake_system_permissions.dart';
import '../../support/pump_app.dart';

/// The camera both scanners share: it reads inside its frame, takes one code
/// at a time, sleeps under a pushed screen and in the background, and turns
/// a refused camera into the way back to Settings.
///
/// The real `MobileScanner` runs; only the hardware is `FakeScannerPlatform`.
void main() {
  late FakeScannerPlatform camera;
  late List<String> codes;
  late GlobalKey<BarcodeCameraViewState> view;

  setUp(() {
    camera = FakeScannerPlatform.install();
    codes = <String>[];
    view = GlobalKey<BarcodeCameraViewState>();
  });

  Future<void> pumpCamera(
    WidgetTester tester, {
    FakeSystemPermissions? permissions,
  }) => pumpScreen(
    tester,
    Scaffold(
      body: BarcodeCameraView(
        key: view,
        hint: 'Point at it',
        onCode: codes.add,
      ),
    ),
    overrides: [
      if (permissions != null)
        systemPermissionsProvider.overrideWithValue(permissions),
    ],
    replaces: <Object>{if (permissions != null) systemPermissionsProvider},
  );

  Future<void> lifecycle(WidgetTester tester, AppLifecycleState state) async {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pumpAndSettle();
  }

  group('reading', () {
    testWidgets('starts the camera and reads only inside a centred frame', (
      WidgetTester tester,
    ) async {
      await pumpCamera(tester);

      final Rect frame = camera.scanWindow!;

      expect(camera.starts, 1);
      // A share of the camera image: inside it, narrower than it, centred.
      expect(frame.left, greaterThan(0));
      expect(frame.right, lessThan(1));
      expect(frame.left, closeTo(1 - frame.right, 0.001));
      expect(frame.width, greaterThan(frame.height));
      expect(find.byType(ScanWindowOverlay), findsOneWidget);
      expect(find.text('Point at it'), findsOneWidget);
    });

    testWidgets('hands over the first code and ignores the rest', (
      WidgetTester tester,
    ) async {
      await pumpCamera(tester);

      camera.scan('5901234123457');
      camera.scan('96385074');
      await tester.pumpAndSettle();

      expect(codes, <String>['5901234123457']);
    });

    testWidgets('a code with no readable value is not a scan', (
      WidgetTester tester,
    ) async {
      await pumpCamera(tester);

      camera.scanUnreadable();
      camera.scan('96385074');
      await tester.pumpAndSettle();

      expect(codes, <String>['96385074']);
    });

    testWidgets('resume takes the next code', (WidgetTester tester) async {
      await pumpCamera(tester);

      camera.scan('5901234123457');
      await tester.pumpAndSettle();
      view.currentState!.resume();
      await tester.pumpAndSettle();
      camera.scan('96385074');
      await tester.pumpAndSettle();

      expect(codes, <String>['5901234123457', '96385074']);
    });

    testWidgets('the torch button reaches the camera', (
      WidgetTester tester,
    ) async {
      await pumpCamera(tester);

      await tester.tap(find.byTooltip('Torch'));
      await tester.pumpAndSettle();

      expect(camera.calls, contains('torch'));
    });
  });

  group('sleeping', () {
    testWidgets('pause turns the camera off, resume turns it back on', (
      WidgetTester tester,
    ) async {
      await pumpCamera(tester);

      view.currentState!.pause();
      await tester.pumpAndSettle();

      expect(camera.calls.last, 'stop');

      view.currentState!.resume();
      await tester.pumpAndSettle();

      expect(camera.calls.last, 'start');
    });

    testWidgets('the background stops it and coming back restarts it', (
      WidgetTester tester,
    ) async {
      await pumpCamera(tester);

      await lifecycle(tester, AppLifecycleState.inactive);
      expect(camera.calls.last, 'stop');

      await lifecycle(tester, AppLifecycleState.resumed);
      expect(camera.calls.last, 'start');
    });

    testWidgets('covered while in the background: stays off on return', (
      WidgetTester tester,
    ) async {
      await pumpCamera(tester);

      await lifecycle(tester, AppLifecycleState.inactive);
      view.currentState!.pause();
      await lifecycle(tester, AppLifecycleState.resumed);

      expect(camera.starts, 1);
    });

    testWidgets('coming back does not restart a camera a screen covers', (
      WidgetTester tester,
    ) async {
      await pumpCamera(tester);

      view.currentState!.pause();
      await tester.pumpAndSettle();
      await lifecycle(tester, AppLifecycleState.inactive);
      await lifecycle(tester, AppLifecycleState.resumed);

      expect(camera.starts, 1, reason: 'filming behind the result screen');
    });
  });

  group('a refused camera', () {
    setUp(() {
      camera.startError = const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    });

    testWidgets('refused for good: says so and offers Settings', (
      WidgetTester tester,
    ) async {
      final FakeSystemPermissions permissions = FakeSystemPermissions(
        blocked: <AppPermission>{AppPermission.camera},
      );

      await pumpCamera(tester, permissions: permissions);

      // The sheet opens on its own, once, over the explanation.
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Camera access is off'), findsWidgets);

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(permissions.settingsOpened, 1);
      expect(find.text('Allow camera'), findsOneWidget);
      // Torch and hint are hidden: nothing sits on top of the reason.
      expect(find.byTooltip('Torch'), findsNothing);
      expect(find.text('Point at it'), findsNothing);
    });

    testWidgets('refused once (Android asks again): no sheet, Allow asks', (
      WidgetTester tester,
    ) async {
      await pumpCamera(tester, permissions: FakeSystemPermissions());

      expect(find.text('Open Settings'), findsNothing);
      expect(camera.starts, 1);

      camera.startError = null;
      await tester.tap(find.text('Allow camera'));
      await tester.pumpAndSettle();

      expect(camera.starts, 2);
      expect(find.text('Allow camera'), findsNothing);
      expect(find.text('Point at it'), findsOneWidget);
    });

    testWidgets('still refused on return: does not ask again in a loop', (
      WidgetTester tester,
    ) async {
      await pumpCamera(tester, permissions: FakeSystemPermissions());

      await lifecycle(tester, AppLifecycleState.inactive);
      await lifecycle(tester, AppLifecycleState.resumed);

      expect(camera.starts, 1);
    });

    testWidgets('allowed in Settings: the camera is back on return', (
      WidgetTester tester,
    ) async {
      final FakeSystemPermissions permissions = FakeSystemPermissions(
        blocked: <AppPermission>{AppPermission.camera},
        granted: <AppPermission>{AppPermission.camera},
      );

      await pumpCamera(tester, permissions: permissions);
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      camera.startError = null;
      await lifecycle(tester, AppLifecycleState.inactive);
      await lifecycle(tester, AppLifecycleState.resumed);

      expect(camera.starts, 2);
      expect(find.text('Allow camera'), findsNothing);

      camera.scan('036000291452');
      await tester.pumpAndSettle();

      expect(codes, <String>['036000291452']);
    });
  });
}
