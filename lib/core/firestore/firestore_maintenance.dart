import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';

/// Every Firestore listener in the app, and the one way to tear the client
/// down without one of them touching it mid-teardown.
///
/// **Why it exists:** a listener opened while `terminate` is running reaches a
/// terminated client, and iOS answers with an uncatchable `NSException` — the
/// app aborts. Signing out re-subscribes `app_config` (it watches the uid) a
/// moment before the wipe terminates the client, so both the fresh-install
/// wipe and sign-out could hit it.
///
/// - [listen] opens a snapshot stream, held back while a [reset] runs.
/// - [reset] detaches every open listener first, terminates and clears the
///   cache, then re-attaches them to the fresh client — so none is left
///   silently dead on the old one.
final class FirestoreMaintenance {
  static Completer<void>? _running;
  static final Set<_Feed<dynamic>> _feeds = <_Feed<dynamic>>{};

  /// Whether a [reset] is in progress.
  static bool get isResetting => _running != null;

  /// [open] is called on subscription, or once a running [reset] finishes,
  /// and again after every later [reset].
  static Stream<T> listen<T>(Stream<T> Function() open) =>
      Stream<T>.multi((MultiStreamController<T> controller) {
        final _Feed<T> feed = _Feed<T>(open, controller);

        _feeds.add(feed);
        controller.onCancel = () {
          _feeds.remove(feed);

          return feed.detach();
        };

        // Checked and opened in one synchronous step, so a listen can never
        // be sent after a terminate that has already started.
        if (_running == null) feed.attach();
      });

  /// Terminate [firestore] and clear its on-disk cache, with no listener open.
  static Future<void> reset(FirebaseFirestore firestore) => hold(() async {
    await firestore.terminate();
    await firestore.clearPersistence();
  });

  /// Runs [work] with every listener detached and every new one held back.
  ///
  /// A second call while one runs waits for it rather than running twice.
  static Future<void> hold(Future<void> Function() work) async {
    final Completer<void>? already = _running;

    if (already != null) return already.future;

    final Completer<void> running = Completer<void>();
    final List<_Feed<dynamic>> open = List<_Feed<dynamic>>.of(_feeds);

    _running = running;
    SdLogger.action(
      LogTagConstant.firestore,
      'Firestore reset',
      <String, Object>{'listeners': open.length},
    );

    try {
      for (final _Feed<dynamic> feed in open) {
        await feed.detach();
      }

      await work();
    } finally {
      _running = null;
      running.complete();

      // Every feed still subscribed, including any opened during the hold.
      for (final _Feed<dynamic> feed in List<_Feed<dynamic>>.of(_feeds)) {
        feed.attach();
      }

      SdLogger.info(
        LogTagConstant.firestore,
        'Firestore listeners reattached',
        <String, Object>{'listeners': _feeds.length},
      );
    }
  }
}

/// One subscriber's connection to its source, which [FirestoreMaintenance]
/// can drop and re-open around a reset.
class _Feed<T> {
  _Feed(this._open, this._controller);

  final Stream<T> Function() _open;
  final MultiStreamController<T> _controller;
  // Cancelled in [detach] — by a reset, or when the subscriber leaves.
  // ignore: cancel_subscriptions
  StreamSubscription<T>? _source;

  void attach() {
    if (_source != null) return;

    _source = _open().listen(
      _controller.add,
      onError: _controller.addError,
      onDone: _controller.close,
    );
  }

  Future<void> detach() async {
    final StreamSubscription<T>? source = _source;

    _source = null;
    await source?.cancel();
  }
}
