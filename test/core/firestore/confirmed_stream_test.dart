import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/firestore/confirmed_stream.dart';

/// **A cache miss is not an answer, and Firestore cannot tell them apart.**
///
/// A listener opened on a document this device has never held emits
/// immediately — `exists: false`, `isFromCache: true` — and the real document
/// lands a round trip later. The router read that first emission as "this
/// account has no business" and showed the create-business form, then
/// corrected itself half a second later. What is pinned here is that the first
/// value carried is a confirmed one, and that a device with no server still
/// gets one.
///
/// A value is written `cached:<name>` or `server:<name>`, which is the whole
/// of what the gate looks at.
bool _isUnconfirmed(String value) => value.startsWith('cached:');

/// Short enough to wait for in a test, and the only thing these change about
/// the real policy.
const Duration _grace = Duration(milliseconds: 40);

void main() {
  late StreamController<String> source;
  late List<String> seen;
  late List<Object> errors;
  late StreamSubscription<String> subscription;

  setUp(() {
    source = StreamController<String>();
    seen = <String>[];
    errors = <Object>[];
    subscription = ConfirmedStream.of(
      source.stream,
      isUnconfirmed: _isUnconfirmed,
      grace: _grace,
    ).listen(seen.add, onError: errors.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await source.close();
  });

  test('an unconfirmed first answer is held back', () async {
    source.add('cached:no-profile');
    await Future<void>.delayed(Duration.zero);

    // Nothing, deliberately: the watcher keeps reading "still loading", which
    // is the truth.
    expect(seen, isEmpty);
  });

  test('the confirmed answer is the first one carried', () async {
    source.add('cached:no-profile');
    await Future<void>.delayed(Duration.zero);
    source.add('server:profile');
    await Future<void>.delayed(Duration.zero);

    expect(seen, <String>['server:profile']);
  });

  test('later unconfirmed answers pass straight through', () async {
    source.add('server:profile');
    await Future<void>.delayed(Duration.zero);
    // The app's own write, echoing back before it is acknowledged. Holding it
    // would make every edit feel like a network wait.
    source.add('cached:own-write');
    await Future<void>.delayed(Duration.zero);

    expect(seen, <String>['server:profile', 'cached:own-write']);
  });

  test('a device with no server still gets an answer', () async {
    source.add('cached:no-profile');
    await Future<void>.delayed(_grace * 2);

    // A seller on a plane sees the app they had, not a loading screen with no
    // end.
    expect(seen, <String>['cached:no-profile']);
  });

  test('the newest held answer is the one released', () async {
    source.add('cached:older');
    source.add('cached:newer');
    await Future<void>.delayed(_grace * 2);

    expect(seen, <String>['cached:newer']);
  });

  test('an error is an answer and is never held', () async {
    source.addError(StateError('permission denied'));
    await Future<void>.delayed(Duration.zero);

    expect(errors, hasLength(1));
  });
}
