import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/permissions/app_permission.dart';
import 'package:reseller_studio/core/permissions/system_permissions.dart';

/// The Dart half of the `system_permissions` channel.
///
/// The names it sends are what the Swift and Kotlin switches match on, and a
/// channel that fails must read as "not blocked" rather than take a screen
/// down over a permission.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'app.dd.reseller.studio/system_permissions',
  );

  void answer(Future<Object?>? Function(MethodCall call) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);

  tearDown(() => answer((MethodCall _) => null));

  test('asks the native side by the channel name', () async {
    final List<MethodCall> calls = <MethodCall>[];

    answer((MethodCall call) async {
      calls.add(call);

      return true;
    });

    expect(
      await const SystemPermissions().isBlocked(AppPermission.notifications),
      isTrue,
    );
    expect(calls.single.method, 'isBlocked');
    expect(calls.single.arguments, <String, String>{
      'permission': 'notifications',
    });
  });

  test('a failing channel reads as not blocked', () async {
    answer((MethodCall _) async => throw PlatformException(code: 'boom'));

    expect(
      await const SystemPermissions().isBlocked(AppPermission.camera),
      isFalse,
    );
    expect(await const SystemPermissions().openAppSettings(), isFalse);
  });

  test('opening Settings answers what the platform said', () async {
    answer((MethodCall call) async => call.method == 'openAppSettings');

    expect(await const SystemPermissions().openAppSettings(), isTrue);
  });
}
