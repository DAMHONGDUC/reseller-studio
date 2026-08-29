/// Converts typed app analytics values into Firebase-supported parameters.
final class AnalyticsParameterUtils {
  /// Firebase accepts strings and numbers, so booleans use one and zero.
  static Map<String, Object> firebaseSafe(Map<String, Object> parameters) =>
      <String, Object>{
        for (final MapEntry<String, Object> entry in parameters.entries)
          entry.key: switch (entry.value) {
            final bool value => value ? 1 : 0,
            final String value => value,
            final num value => value,
            _ => throw ArgumentError.value(
              entry.value,
              entry.key,
              'Analytics parameters must be a string, number, or boolean.',
            ),
          },
      };
}
