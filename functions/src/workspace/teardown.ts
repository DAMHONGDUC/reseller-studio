import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';

import { db, paths } from '../lib/firestore';

/** Storage objects are removed a page at a time; the bucket API takes a prefix. */
const storagePrefix = (workspaceId: string) => `workspaces/${workspaceId}/`;

/**
 * Erase one business: its documents, its files and the invitations to it.
 *
 * **One function for both callers.** `deleteAccount` removes the workspaces a
 * departing seller solely owns and `deleteWorkspace` removes one on request —
 * two copies of a cascade is how one of them ends up forgetting the Storage
 * objects, and the leftovers are invisible until a bucket bill arrives.
 *
 * **Deleting the membership documents is what updates every member's
 * `users/{uid}.workspaceIds`**: `recursiveDelete` fires `onMemberWritten` for
 * each one, so nothing here touches a user document directly. A seller whose
 * `lastWorkspaceId` pointed at this business falls back to the first they
 * still belong to (hard rule 11b), and to workspace setup when there is none.
 *
 * **Idempotent**: every step is a delete, so a retry after a partial run
 * finishes the job rather than failing on what is already gone.
 */
export async function deleteWorkspaceData(workspaceId: string): Promise<void> {
  await db().recursiveDelete(db().doc(paths.workspace(workspaceId)));

  await Promise.all([
    deleteWorkspaceFiles(workspaceId),
    deleteWorkspaceInvites(workspaceId),
  ]);
}

/**
 * Item photos, receipts and the workspace logo.
 *
 * **A failure here does not fail the delete.** Storage and Firestore are two
 * services, and a bucket that is briefly unavailable must not leave the seller
 * with a business they cannot remove — the log is what makes the leftover
 * objects findable.
 */
async function deleteWorkspaceFiles(workspaceId: string): Promise<void> {
  try {
    await getStorage().bucket().deleteFiles({ prefix: storagePrefix(workspaceId) });
  } catch (error) {
    logger.error('workspace files not deleted', { workspaceId, error });
  }
}

/**
 * Invitations to a business that no longer exists.
 *
 * `invites/` is top-level, so `recursiveDelete` on the workspace never reaches
 * it — and an invite left behind is one somebody could accept into nothing.
 */
async function deleteWorkspaceInvites(workspaceId: string): Promise<void> {
  try {
    const pending = await db()
      .collection(paths.invites)
      .where('workspaceId', '==', workspaceId)
      .get();

    await Promise.all(pending.docs.map((doc) => doc.ref.delete()));

    logger.info('workspace invites deleted', { workspaceId, count: pending.size });
  } catch (error) {
    logger.error('workspace invites not deleted', { workspaceId, error });
  }
}
