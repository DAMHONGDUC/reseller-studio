import 'workspace_collections.dart';

/// Everything a Firestore repository needs to know about *whose* data it is
/// reading: the paths, the currency and the actor.
///
/// One object rather than three constructor arguments. Dart cannot name a
/// private field as a named parameter, so the alternative is three positional
/// strings — and `('USD', uid)` swapped for `(uid, 'USD')` is a bug that
/// compiles, writes every document with the wrong `createdBy`, and shows up
/// weeks later in an audit log.
class WorkspaceContext {
  const WorkspaceContext({
    required this.collections,
    required this.currency,
    required this.uid,
  });

  /// Every path under this workspace. A repository cannot name a collection
  /// outside it (hard rule 14).
  final WorkspaceCollections collections;

  /// The workspace's currency — what an amount stored without its own
  /// currency field is denominated in.
  final String currency;

  /// Who is writing. Lands in `createdBy` on every document.
  final String uid;

  String get workspaceId => collections.workspaceId;
}
