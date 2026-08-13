import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The app's source of "now" for anything **derived at read time**.
///
/// A screen that decides what is overdue, stale or expired by calling
/// `DateTime.now()` cannot be tested: the seeded dataset places its rows
/// relative to a fixed instant, so the same assertion passes in June and
/// fails in August as those rows drift past the wall clock. Reading the
/// instant from a provider makes it an override, and a test pins it.
///
/// **The boundary is read time only.** What is *recorded* — `createdAt`,
/// `deletedAt`, the instant an order shipped, the default date on a form —
/// stays a real `DateTime.now()`, because that is a fact about when something
/// happened rather than a figure computed from it.
class AppClock {
  const AppClock();

  DateTime now() => DateTime.now();
}

/// The one clock the app reads. Overridden in tests with a fixed instant.
final Provider<AppClock> clockProvider = Provider<AppClock>(
  (Ref ref) => const AppClock(),
);
