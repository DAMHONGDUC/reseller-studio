import '../entities/user_profile.dart';
import '../entities/workspace.dart';

/// Reading and writing workspaces, memberships and the user's own profile.
///
/// One repository for all three because they are written together: creating a
/// workspace writes the workspace, the owner's membership document and the
/// user's `workspaceIds` in a single batch. Splitting them would let a client
/// crash between two writes and leave a workspace nobody is a member of —
/// which, under `firestore.rules`, nobody could ever read again.
abstract interface class WorkspaceRepository {
  /// The signed-in person's own record, live.
  Stream<UserProfile?> watchProfile(String uid);

  Stream<Workspace?> watchWorkspace(String workspaceId);

  Stream<List<Member>> watchMembers(String workspaceId);

  /// Create the profile document if this account has none.
  ///
  /// Called once after every sign-in rather than only after sign-up: an
  /// account created before this document existed, or one whose write failed,
  /// otherwise has no way to ever get one.
  Future<void> ensureProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
  });

  /// Create a workspace, its owner membership and the user's pointer to it,
  /// as one batch. Returns the new workspace id.
  Future<String> createWorkspace({
    required String name,
    required String country,
    required String currency,
    required String ownerId,
    String? ownerName,
    String? ownerEmail,
    String? businessType,
  });

  Future<void> updateWorkspace(Workspace workspace);

  /// Remember which workspace to reopen.
  Future<void> setLastWorkspace({
    required String uid,
    required String workspaceId,
  });
}
