import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../domain/entities/pending_invite.dart';

/// How an invitation is read. Write-side is a Cloud Function, so there is no
/// `toMap` here and there should never be one.
final class InviteDto {
  static PendingInvite toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};

    return PendingInvite(
      id: doc.id,
      workspaceId: FirestoreMapper.stringOrNull(data['workspaceId']) ?? '',
      // An unknown role reads as the least privileged one rather than as its
      // neighbour: a document written by a newer build must never grant more
      // than it says (`docs/rules/BACKEND.md`).
      role:
          FirestoreMapper.enumOrNull(MemberRole.values, data['role']) ??
          MemberRole.viewer,
      workspaceName: FirestoreMapper.stringOrNull(data['workspaceName']),
    );
  }
}
