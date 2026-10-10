import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/firestore/firestore_maintenance.dart';

/// No Firestore listener may be open, or open itself, while the client is
/// torn down — on iOS that is an uncatchable abort (TestFlight builds 45-46
/// crashed on launch this way, after the fresh-install wipe's sign-out made
/// `app_config` re-subscribe a moment before `terminate`).
void main() {
  test('a listener opened during a reset waits until it is over', () async {
    final _Source source = _Source();
    final Completer<void> teardown = Completer<void>();
    final Future<void> reset = FirestoreMaintenance.hold(() => teardown.future);
    final List<int> events = <int>[];
    final StreamSubscription<int> subscription = FirestoreMaintenance.listen(
      source.open,
    ).listen(events.add);

    await pumpEventQueue();
    expect(source.log, isEmpty, reason: 'opened against a dying client');

    teardown.complete();
    await reset;
    source.controller!.add(1);
    await pumpEventQueue();

    expect(source.log, <String>['open']);
    expect(events, <int>[1]);
    await subscription.cancel();
  });

  test('an open listener is dropped before the work and back after', () async {
    final _Source source = _Source();
    final List<int> events = <int>[];
    final StreamSubscription<int> subscription = FirestoreMaintenance.listen(
      source.open,
    ).listen(events.add);

    await FirestoreMaintenance.hold(() async => source.log.add('terminate'));
    source.controller!.add(7);
    await pumpEventQueue();

    expect(source.log, <String>['open', 'cancel', 'terminate', 'open']);
    expect(events, <int>[7], reason: 'the subscriber kept its stream');
    await subscription.cancel();
  });

  test('a subscriber that leaves during a reset is never opened', () async {
    final _Source source = _Source();
    final Completer<void> teardown = Completer<void>();
    final Future<void> reset = FirestoreMaintenance.hold(() => teardown.future);

    await FirestoreMaintenance.listen(source.open).listen((_) {}).cancel();
    teardown.complete();
    await reset;

    expect(source.log, isEmpty);
  });

  test('a failed reset still lets listeners through', () async {
    final _Source source = _Source();

    await expectLater(
      FirestoreMaintenance.hold(() async => throw StateError('terminate')),
      throwsStateError,
    );

    expect(FirestoreMaintenance.isResetting, isFalse);

    final StreamSubscription<int> subscription = FirestoreMaintenance.listen(
      source.open,
    ).listen((_) {});

    expect(source.log, <String>['open']);
    await subscription.cancel();
  });

  test('two resets at once run the work once', () async {
    int runs = 0;
    final Completer<void> teardown = Completer<void>();
    final Future<void> first = FirestoreMaintenance.hold(() {
      runs++;

      return teardown.future;
    });
    final Future<void> second = FirestoreMaintenance.hold(() async => runs++);

    teardown.complete();
    await Future.wait(<Future<void>>[first, second]);

    expect(runs, 1);
  });
}

/// A source that records when it is opened and when it is cancelled.
class _Source {
  final List<String> log = <String>[];
  // A test double; the subscriber's cancel is what each case checks.
  // ignore: close_sinks
  StreamController<int>? controller;

  Stream<int> open() {
    log.add('open');
    controller = StreamController<int>(onCancel: () => log.add('cancel'));

    return controller!.stream;
  }
}
