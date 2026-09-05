import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../pricing/domain/services/profit_calculator.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/workspace.dart';
import '../../workspace_constant.dart';

/// How a [Workspace] is stored.
final class WorkspaceDto {
  static Workspace toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};

    return Workspace(
      id: doc.id,
      name: FirestoreMapper.stringOrNull(data['name']) ?? '',
      ownerId: FirestoreMapper.stringOrNull(data['ownerId']) ?? '',
      country: FirestoreMapper.stringOrNull(data['country']) ?? 'US',
      currency: FirestoreMapper.stringOrNull(data['currency']) ?? 'USD',
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      timezone: FirestoreMapper.stringOrNull(data['timezone']),
      businessType: FirestoreMapper.stringOrNull(data['businessType']),
      logoUrl: FirestoreMapper.stringOrNull(data['logoUrl']),
      staleThresholdDays:
          FirestoreMapper.intOrNull(data['staleThresholdDays']) ??
          StaleInventoryPolicy.defaultThresholdDays,
      lowStockThreshold:
          FirestoreMapper.intOrNull(data['lowStockThreshold']) ??
          LowStockPolicy.defaultThreshold,
      planningFeeRate:
          FirestoreMapper.doubleOrNull(data['planningFeeRate']) ??
          WorkspaceConstant.defaultPlanningFeeRate,
    );
  }

  /// The update payload.
  ///
  /// **`ownerId` is not written here.** `firestore.rules` refuses an update
  /// that changes it — transferring ownership has to move the membership
  /// documents in the same transaction, which is a Cloud Function's job.
  static Map<String, Object?> toUpdateMap(Workspace workspace) =>
      FirestoreMapper.pruned(<String, Object?>{
        'name': workspace.name,
        'country': workspace.country,
        'currency': workspace.currency,
        'timezone': workspace.timezone,
        'businessType': workspace.businessType,
        'logoUrl': workspace.logoUrl,
        'staleThresholdDays': workspace.staleThresholdDays,
        'lowStockThreshold': workspace.lowStockThreshold,
        'planningFeeRate': workspace.planningFeeRate,
        'updatedAt': FirestoreMapper.serverTimestamp,
      });
}

/// How a [Member] — the ACL row — is stored.
///
/// `displayName` and `email` are denormalised so the Team screen renders
/// without reading anyone else's `users/{uid}` document, which the rules
/// forbid. They go stale when someone renames themselves; the alternative is
/// either a leak or a fan-out read per member.
final class MemberDto {
  static Member toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};

    return Member(
      uid: doc.id,
      role:
          FirestoreMapper.enumOrNull(MemberRole.values, data['role']) ??
          MemberRole.viewer,
      joinedAt: FirestoreMapper.dateOr(data['joinedAt'], DateTime.now()),
      displayName: FirestoreMapper.stringOrNull(data['displayName']),
      email: FirestoreMapper.stringOrNull(data['email']),
      photoUrl: FirestoreMapper.stringOrNull(data['photoUrl']),
    );
  }

  static Map<String, Object?> toMap(Member member) =>
      FirestoreMapper.pruned(<String, Object?>{
        'role': member.role.name,
        'displayName': member.displayName,
        'email': member.email,
        'photoUrl': member.photoUrl,
        'joinedAt': Timestamp.fromDate(member.joinedAt),
      });
}

/// How a [UserProfile] is stored.
final class UserProfileDto {
  static UserProfile toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};

    return UserProfile(
      uid: doc.id,
      displayName: FirestoreMapper.stringOrNull(data['displayName']),
      email: FirestoreMapper.stringOrNull(data['email']),
      photoUrl: FirestoreMapper.stringOrNull(data['photoUrl']),
      lastWorkspaceId: FirestoreMapper.stringOrNull(data['lastWorkspaceId']),
      workspaceIds: FirestoreMapper.stringList(data['workspaceIds']),
    );
  }
}
