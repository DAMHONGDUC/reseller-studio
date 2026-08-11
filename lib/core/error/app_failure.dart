/// What went wrong, in terms the UI can act on.
///
/// Every repository turns whatever it caught — a `FirebaseException`, a
/// `SocketException`, a `TypeError` from a malformed document — into one of
/// these before it crosses into `domain/`. Presentation therefore never sees
/// a Firebase type, and the plan's rule that **users never see a raw
/// technical error** (§31) is enforced by the type system rather than by
/// everyone remembering.
///
/// The set is deliberately small. A failure earns a case here only when the
/// UI would do something *different* about it; everything else is [unknown]
/// and renders the generic message.
enum AppFailureKind {
  /// The device could not reach the backend. Firestore has already queued the
  /// write locally, so the honest message is "saved, will sync" — not "failed".
  offline,

  /// Signed out, session expired, or the credential was rejected.
  unauthenticated,

  /// Signed in, but not allowed — the wrong workspace, or a role that cannot
  /// do this. See the workspace rules.
  permissionDenied,

  /// The document is gone. Usually a stale link or a row another member
  /// deleted while this screen was open.
  notFound,

  /// The server rejected the data. A bug in the client, or a state transition
  /// whose extra requirements were not met (plan §29).
  invalidData,

  /// A plan limit was hit — free-tier inventory cap, marketplace connection
  /// count.
  limitReached,

  /// Anything else.
  unknown,
}

/// A failure on its way to the UI.
///
/// [kind] is what the UI branches on. [technicalMessage] exists **for the log
/// and Crashlytics only** and must never be rendered: it carries the original
/// exception's text, which is exactly the raw error the plan forbids showing.
/// The screen picks its own localized string from [kind].
class AppFailure implements Exception {
  const AppFailure(this.kind, {this.technicalMessage, this.cause});

  const AppFailure.offline({String? technicalMessage})
    : this(AppFailureKind.offline, technicalMessage: technicalMessage);

  const AppFailure.unknown({String? technicalMessage, Object? cause})
    : this(
        AppFailureKind.unknown,
        technicalMessage: technicalMessage,
        cause: cause,
      );

  final AppFailureKind kind;

  /// Developer-facing detail. Logged, never displayed.
  final String? technicalMessage;

  /// The exception this was built from, kept so the stack trace stays useful.
  final Object? cause;

  @override
  String toString() =>
      'AppFailure(${kind.name}${technicalMessage == null ? '' : ': $technicalMessage'})';
}
