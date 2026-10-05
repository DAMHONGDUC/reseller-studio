/// The error a test report carries, so the dashboard files it under its own
/// issue rather than beside a real failure.
final class CrashlyticsTestException implements Exception {
  const CrashlyticsTestException();

  @override
  String toString() =>
      'CrashlyticsTestException: test report sent from the debug menu';
}
