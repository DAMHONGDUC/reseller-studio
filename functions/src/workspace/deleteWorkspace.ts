import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { requireFreshUid } from '../lib/caller';
import { db, paths } from '../lib/firestore';
import { deleteWorkspaceData } from './teardown';

/**
 * Delete one business without deleting the account with it.
 *
 * **`deleteAccount` already walked the subcollections; what was missing was
 * doing it for a single workspace.** A seller who tried a second business and
 * wants it gone had one option before this: delete their whole account.
 *
 * What it enforces, and why none of it can be a security rule:
 *
 * - **Only an `owner` may delete.** An admin can change the business; ending
 *   it is the one thing that belongs to whoever owns it (`MemberRole.canOwn`).
 * - **The sign-in must be recent**, the same guard `deleteAccount` uses. This
 *   destroys records for every member, not only the caller.
 * - **The cascade needs the Admin SDK.** Firestore does not cascade, so
 *   `workspaces/{id}` is `allow delete: if false` for clients and the
 *   subcollections are walked here.
 *
 * **Idempotent**: a workspace that is already gone is a success, not a
 * `permission-denied`. A client that lost the answer to its first call would
 * otherwise be shown a failure for the delete that actually worked.
 */
export const deleteWorkspace = onCall(async (request) => {
  const uid = requireFreshUid(request);
  const workspaceId = String(request.data?.workspaceId ?? '');

  if (!workspaceId) {
    throw new HttpsError('invalid-argument', 'workspaceId is required.');
  }

  const workspace = await db().doc(paths.workspace(workspaceId)).get();

  if (!workspace.exists) {
    logger.info('workspace already deleted', { workspaceId });

    return { workspaceId, deleted: false };
  }

  const caller = await db().doc(paths.member(workspaceId, uid)).get();

  if (caller.get('role') !== 'owner') {
    throw new HttpsError('permission-denied', 'Only the owner can delete a business.');
  }

  const members = await db().collection(paths.members(workspaceId)).count().get();

  await deleteWorkspaceData(workspaceId);

  // Counts, never names — hard rule 9. No business name, no member emails.
  logger.info('workspace deleted', {
    workspaceId,
    membersRemoved: members.data().count,
  });

  return { workspaceId, deleted: true };
});
