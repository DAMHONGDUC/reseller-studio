import '../../../carriers/domain/entities/carrier.dart';
import '../../../inventory/domain/entities/item_category.dart';
import '../../../marketplaces/domain/entities/marketplace.dart';
import '../entities/user_profile.dart';
import '../entities/workspace.dart';

/// Reading and writing workspaces, memberships and the user's own profile.
///
/// One repository owns creation because its writes have a required order:
/// workspace, owner membership, then one batch containing the marketplace
/// defaults and the user's pointer. The pointer is withheld until the business
/// is ready to read.
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

  /// Create a workspace, its owner membership, default reference data and the
  /// user's pointer. Returns the new workspace id.
  Future<String> createWorkspace({
    required String name,
    required String country,
    required String currency,
    required String ownerId,
    String? ownerName,
    String? ownerEmail,
    String? businessType,
    required List<Marketplace> marketplaces,
    required List<ItemCategory> categories,
    required List<Carrier> carriers,
  });

  Future<void> updateWorkspace(Workspace workspace);

  /// Erase one business: its records, its files and the invitations to it.
  ///
  /// **A Cloud Function, not a client delete** — Firestore does not cascade,
  /// so `workspaces/{id}` is `allow delete: if false` and the subcollections
  /// are walked with the Admin SDK. Owner only, and the function is what
  /// checks that; the UI only decides whether to draw the control.
  Future<void> deleteWorkspace(String workspaceId);

  /// Remember which workspace to reopen.
  Future<void> setLastWorkspace({
    required String uid,
    required String workspaceId,
  });
}
