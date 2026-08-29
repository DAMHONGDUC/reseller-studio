import '../../../listings/domain/enums/listing_status.dart';
import '../entities/pending_invite.dart';

/// Membership as an action rather than as a document.
///
/// **Every write here is a Cloud Function, and none of it could be a client
/// write.** `invites/` is `allow write: if false` because the seat limit needs
/// a count of a collection; the membership rules refuse anyone editing their
/// own document (hard rule 11); and the last-owner check needs to count the
/// owners. A rule can read one document — none of those three fit.
///
/// Reading is the exception and stays a plain query: an invitation is
/// readable by the person it is addressed to, which is exactly what the rule
/// on `invites/` allows.
abstract interface class TeamRepository {
  /// Invitations addressed to this person, across every business.
  ///
  /// **Scoped by their own email**, because that is the only shape the rules
  /// permit — there is no way to ask "who has been invited to my workspace",
  /// which is also why the Team screen shows members and not pending invites.
  Stream<List<PendingInvite>> watchMyInvites(String email);

  /// Invite somebody by email. Returns the invite id.
  ///
  /// Idempotent server-side: the id is derived from the workspace and the
  /// address, so inviting the same person twice rewrites one document.
  Future<String> invite({
    required String workspaceId,
    required String email,
    required MemberRole role,
  });

  /// Turn an invitation into a membership. Returns the workspace joined, so
  /// the caller can switch to it.
  Future<String> acceptInvite(String inviteId);

  Future<void> removeMember({
    required String workspaceId,
    required String memberUid,
  });

  /// Change what somebody may do. The same callable as [removeMember] —
  /// **the last owner may be neither demoted nor removed**, and that is one
  /// check over one count, not two.
  Future<void> changeRole({
    required String workspaceId,
    required String memberUid,
    required MemberRole role,
  });
}
