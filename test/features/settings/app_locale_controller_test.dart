import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/settings/presentation/controllers/app_locale_controller.dart';

void main() {
  test('a shipped code pins that locale', () {
    expect(AppLocaleController.parse('vi'), const Locale('vi'));
  });

  test('nothing stored, or a code no longer shipped, follows the device', () {
    expect(AppLocaleController.parse(null), isNull);
    expect(AppLocaleController.parse(''), isNull);
    expect(AppLocaleController.parse('ja'), isNull);
  });
}
