/// What a record written before anyone signed in is stamped with.
///
/// **Sentinels, not nulls** (`docs/rules/GUEST_MODE.md`). Making
/// `WorkspaceContext.uid` nullable to accommodate a guest would ask every
/// repository to decide separately what a null means — the same failure as an
/// `if` at a call site, once per repository. These keep every signature below
/// the context untouched, and the drain restamps both columns at sign-in.
final class GuestConstant {
  /// The `createdBy` of every row a guest writes.
  ///
  /// **Never reaches Firestore.** It cannot in practice —
  /// `firestore.rules` checks `ownerId == request.auth.uid` — but the drain
  /// asserts it anyway, because a row attributed to an account that does not
  /// exist is not a failure anyone would notice.
  static const String uid = 'guest';

  /// The `workspaceId` column on every local row.
  ///
  /// A fixed string rather than a uuid: there is exactly one guest business
  /// per device, and a constant is what makes a local row readable in a
  /// debugger. The composite key `{workspaceId}_{id}` (hard rule 14) still
  /// spells out the same way.
  static const String workspaceId = 'local';

  /// The business a guest gets before they have named one.
  ///
  /// Not a user-facing string: it is overwritten the moment the seller edits
  /// the business, and it is never shown untranslated anywhere a seller reads
  /// — the workspace name field carries it (hard rule 7 governs the *label*,
  /// not stored data).
  static const String workspaceName = 'My Business';
}
