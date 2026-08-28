import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/analytics/analytics_parameter_utils.dart';

void main() {
  test('Firebase analytics parameters convert boolean flags to numbers', () {
    final Map<String, Object> parameters = AnalyticsParameterUtils.firebaseSafe(
      <String, Object>{
        'via_quick_add': true,
        'has_photo': false,
        'count': 3,
        'provider': 'google',
      },
    );

    expect(parameters, <String, Object>{
      'via_quick_add': 1,
      'has_photo': 0,
      'count': 3,
      'provider': 'google',
    });
    expect(
      parameters.values.every(
        (Object value) => value is String || value is num,
      ),
      isTrue,
    );
  });

  test('Firebase analytics parameters reject unsupported values', () {
    expect(
      () => AnalyticsParameterUtils.firebaseSafe(<String, Object>{
        'invalid': const <String>['value'],
      }),
      throwsArgumentError,
    );
  });
}
