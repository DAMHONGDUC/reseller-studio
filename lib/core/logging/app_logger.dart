import 'package:logger/logger.dart';

import 'crash_reporter.dart';

/// App-wide logger — the single funnel every error in the app passes through.
///
/// The master plan (§31) asks for two destinations and this class is the fork:
///
/// ```text
/// AppLogger.error(...)
///        │
///   ┌────┴────┐
///   ▼         ▼
/// debug    Crashlytics
/// console  (non-fatal)
/// ```
///
/// **Debug builds print; release builds report.** The console sink is gated
/// on [enabled], which is true only when asserts run — so nothing is printed
/// in profile or release, and nothing a developer typed into a log message
/// can leak from a shipped binary. [error] additionally hands the failure to
/// [CrashReporter], which is a no-op until `bootstrap` initializes Firebase.
///
/// **Never log a password, a token, an OAuth secret or a buyer's address.**
/// Plan §31: production errors go to a third-party service, and a log line is
/// the easiest way for a credential to end up there. Log the *shape* of a
/// failure ('marketplace token refresh failed'), never its contents.
///
/// Categories, picked by intent so the console reads as a story of what the
/// app is doing:
/// - [action]  — a user-driven action ('item created', 'order shipped')
/// - [info]    — notable state or flow ('workspace switched')
/// - [warning] — recoverable oddities ('sync retried')
/// - [error]   — a caught failure, with its error object and stack trace
/// - [debug]   — fine detail while chasing something down
final class AppLogger {
  /// True only in debug builds (asserts run) — the on/off switch for console
  /// output. Mutable so tests can silence it.
  static bool enabled = _assertsEnabled();

  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(methodCount: 0, colors: false, printEmojis: false),
  );

  static void action(String message, [Object? data]) {
    if (!enabled) return;
    _logger.i(_compose('🎯 $message', data));
  }

  static void info(String message, [Object? data]) {
    if (!enabled) return;
    _logger.i(_compose(message, data));
  }

  static void debug(String message, [Object? data]) {
    if (!enabled) return;
    _logger.d(_compose(message, data));
  }

  static void warning(String message, [Object? data]) {
    if (!enabled) return;
    _logger.w(_compose(message, data));
  }

  /// A caught failure. Prints in debug, and reports as a Crashlytics
  /// non-fatal in every build.
  ///
  /// [message] says *what was being attempted*, not what went wrong — the
  /// error object already carries that, and 'failed to load inventory' is
  /// what makes a Crashlytics issue findable six weeks later.
  ///
  /// [data] is what the call was doing — the arguments, the collection, the
  /// record id. Without it a report says a save failed but not which save,
  /// and the only way to find out is to reproduce the run. **Never a
  /// credential or a buyer address** (hard rule 9): the id, the key name, the
  /// count.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    final String composed = _compose(message, data);

    if (enabled) {
      _logger.e(composed, error: error, stackTrace: stackTrace);
    }

    CrashReporter.instance.recordError(
      composed,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _compose(String message, Object? data) =>
      data == null ? message : '$message — $data';

  /// Pure-Dart debug-mode check: the assignment only runs when asserts are on,
  /// so this is true in debug and false in release/profile — no `dart:ui` or
  /// Flutter import needed, which keeps this callable from `domain/`.
  static bool _assertsEnabled() {
    bool enabled = false;
    assert(enabled = true);

    return enabled;
  }
}
