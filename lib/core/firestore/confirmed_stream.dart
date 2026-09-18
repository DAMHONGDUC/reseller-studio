import 'dart:async';

/// Holds back a value the source has not confirmed yet.
///
/// **Written for one problem: Firestore answers from its cache first, and a
/// cache miss looks exactly like a document that does not exist.**
/// `snapshots()` emits immediately — `exists: false`,
/// `metadata.isFromCache: true` — and the real document lands a round trip
/// later. For most reads that is a feature; for the one document that decides
/// *where the app sends the seller* it is a wrong answer given confidently,
/// and it is what put a returning seller on the create-business form for half
/// a second after every sign-in.
///
/// So the first value this passes on is a confirmed one. Everything after it
/// goes straight through: once a listener is attached, its later unconfirmed
/// values are the app's own writes echoing back, and holding those would make
/// every edit feel like a network wait.
///
/// **A device with no signal still gets an answer.** Nothing arrives from the
/// server there, ever, so [grace] bounds the wait and the held value is
/// released when it expires. A seller on a plane sees the app they had rather
/// than a loading screen with no end.
///
/// Generic rather than typed on a snapshot, because `DocumentSnapshot` is
/// sealed and a rule that cannot be tested without a live backend is a rule
/// nobody checks. [FirestoreStream.confirmedDocument] is the one caller and
/// owns the Firestore half of it.
final class ConfirmedStream {
  /// How long an unconfirmed value is held.
  ///
  /// The class *is* the policy, so the number lives with it. Long enough that
  /// a slow mobile round trip is not mistaken for being offline, short enough
  /// that being offline is not mistaken for a hang.
  static const Duration grace = Duration(seconds: 3);

  /// [source] with its leading unconfirmed values held back.
  ///
  /// [isUnconfirmed] is asked of every value until one answers false; after
  /// that the gate is open for the life of the stream.
  static Stream<T> of<T>(
    Stream<T> source, {
    required bool Function(T value) isUnconfirmed,
    Duration grace = ConfirmedStream.grace,
  }) => _ConfirmedGate<T>(source, isUnconfirmed, grace).stream;
}

/// The held state of one [ConfirmedStream] — a class rather than a closure, so
/// the timer and the subscription are torn down in one place.
class _ConfirmedGate<T> {
  _ConfirmedGate(this._source, this._isUnconfirmed, this._grace) {
    _controller = StreamController<T>(onListen: _start, onCancel: _stop);
  }

  final Stream<T> _source;
  final bool Function(T value) _isUnconfirmed;
  final Duration _grace;

  late final StreamController<T> _controller;
  StreamSubscription<T>? _subscription;
  Timer? _deadline;
  T? _held;
  bool _confirmed = false;

  Stream<T> get stream => _controller.stream;

  void _start() {
    _subscription = _source.listen(
      _onValue,
      // An error IS an answer — the caller maps it and shows a screen the
      // seller can act on — so it is never held.
      onError: _controller.addError,
      onDone: _controller.close,
    );
  }

  Future<void> _stop() async {
    _deadline?.cancel();

    await _subscription?.cancel();
  }

  void _onValue(T value) {
    if (_confirmed || !_isUnconfirmed(value)) {
      _pass(value);

      return;
    }

    // Kept rather than dropped: it is what the seller gets if the source never
    // confirms anything, and the newest one is the closest thing to the truth.
    _held = value;
    _deadline ??= Timer(_grace, _releaseHeld);
  }

  void _releaseHeld() {
    final T? pending = _held;

    if (pending != null) _pass(pending);
  }

  void _pass(T value) {
    _confirmed = true;
    _deadline?.cancel();
    _deadline = null;
    _held = null;

    _controller.add(value);
  }
}
