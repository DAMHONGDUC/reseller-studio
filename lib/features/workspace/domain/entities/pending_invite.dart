import '../../../listings/domain/enums/listing_status.dart';

/// An invitation addressed to the signed-in person.
///
/// **Keyed by email, and readable only by the person it names.**
/// `firestore.rules` scopes `invites/` to `request.auth.token.email`, which is
/// what lets somebody find their invitation before they are a member of
/// anything — and what stops the Team screen listing invitations it sent, or
/// anyone else's.
///
/// The workspace name is denormalised onto it for the same reason a member's
/// name is: the invitee cannot read `workspaces/{id}` until they have joined
/// it, so without the copy the sheet would offer "you have been invited to a
/// business" and be unable to say which.
class PendingInvite {
  const PendingInvite({
    required this.id,
    required this.workspaceId,
    required this.role,
    this.workspaceName,
  });

  final String id;
  final String workspaceId;

  /// What accepting grants. Never `owner` — `inviteMember` refuses it, so a
  /// business cannot acquire a second owner by invitation.
  final MemberRole role;

  final String? workspaceName;
}
