import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/bootstrap/app_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Flutter requests portrait-up only', () async {
    final List<MethodCall> calls = <MethodCall>[];
    final TestDefaultBinaryMessenger messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (
      MethodCall call,
    ) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await AppBootstrap.lockPortrait();

    expect(calls.single.method, 'SystemChrome.setPreferredOrientations');
    expect(calls.single.arguments, <String>['DeviceOrientation.portraitUp']);
  });

  test('startup registers orientation before its app builder can run', () {
    final String source = File(
      'lib/core/bootstrap/app_bootstrap.dart',
    ).readAsStringSync();
    expect(
      source,
      contains(
        "SdBootstrapStep(name: 'Portrait orientation', run: lockPortrait)",
      ),
    );
  });

  test('both native platforms declare the same portrait policy', () {
    final String plist = File('ios/Runner/Info.plist').readAsStringSync();
    final String manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    for (final String key in <String>[
      'UISupportedInterfaceOrientations',
      'UISupportedInterfaceOrientations~ipad',
    ]) {
      final RegExp pattern = RegExp(
        '<key>$key</key>\\s*<array>(.*?)</array>',
        dotAll: true,
      );
      final String orientations = pattern.firstMatch(plist)!.group(1)!;
      expect(
        RegExp(
          '<string>(.*?)</string>',
        ).allMatches(orientations).map((Match match) => match.group(1)),
        <String>['UIInterfaceOrientationPortrait'],
      );
    }
    expect(
      plist,
      matches(RegExp(r'<key>UIRequiresFullScreen</key>\s*<true\s*/>')),
    );
    expect(manifest, contains('android:screenOrientation="portrait"'));
    expect(
      manifest,
      matches(
        RegExp(
          r'android:name="android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY"\s+android:value="true"',
        ),
      ),
    );
  });
}
