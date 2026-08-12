/// The person, not their business.
///
/// Deliberately thin (`docs/DATA_MODEL.md`): a name, an email, and which
/// workspaces they belong to. **No business data lives here** — a user is not
/// a workspace, and treating them as one is what makes adding a team member a
/// migration later.
class UserProfile {
  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.lastWorkspaceId,
    this.workspaceIds = const <String>[],
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  /// Where the app reopens. Null on a brand-new account, which is what sends
  /// the user to workspace setup rather than to Home.
  final String? lastWorkspaceId;

  /// Every workspace this person is a member of.
  ///
  /// Stored on the user rather than found by querying memberships, because
  /// that query would be a collection group over `members` — and the security
  /// rules deliberately scope member reads to one workspace at a time, so
  /// there is no way to ask "which workspaces am I in?" from the client
  /// without this list. A Cloud Function keeps it in step when an invite is
  /// accepted.
  final List<String> workspaceIds;

  /// Which workspace to open: the last one used, else the first they belong
  /// to, else none — and none means onboarding is not finished.
  String? get resolvedWorkspaceId {
    final String? last = lastWorkspaceId;

    if (last != null && workspaceIds.contains(last)) return last;

    return workspaceIds.isEmpty ? null : workspaceIds.first;
  }
}
