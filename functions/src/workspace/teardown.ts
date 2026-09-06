import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';

import { db, paths, rowsOf, workspaceTables } from '../lib/firestore';

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
 * **Deleting the membership rows is what updates every member's
 * `users/{uid}.workspaceIds`**: each delete fires `onMemberWritten`, so
 * nothing here touches a user document directly. A seller whose
 * `lastWorkspaceId` pointed at this business falls back to the first they
 * still belong to (hard rule 11b), and to workspace setup when there is none.
 *
 * **A sweep per table, because the tables are flat** (hard rule 14). There is
 * no subtree under `workspaces/{id}` to recurse into any more — the rows live
 * in top-level tables and are found by their `workspaceId` column, so the
 * cascade is `workspaceTables` plus a query each. A table missing from that
 * list is a table whose rows outlive the business.
 *
 * **The workspace row goes last.** Every sweep above is authorised by it in
 * `firestore.rules`; deleting it first would leave anything that retried
 * unable to prove it may finish.
 *
 * **Idempotent**: every step is a delete, so a retry after a partial run
 * finishes the job rather than failing on what is already gone.
 */
export async function deleteWorkspaceData(workspaceId: string): Promise<void> {
  for (const table of workspaceTables) {
    await deleteRowsIn(workspaceId, table);
  }

  await db().doc(paths.workspace(workspaceId)).delete();

  await Promise.all([
    deleteWorkspaceFiles(workspaceId),
    deleteWorkspaceInvites(workspaceId),
  ]);
}

/**
 * Every row one workspace owns in one table, a page at a time.
 *
 * **Paged rather than read whole.** A seller with thousands of items would
 * otherwise load them all into memory to delete them, and a batch caps at 500
 * writes anyway.
 */
async function deleteRowsIn(workspaceId: string, table: string): Promise<void> {
  const pageSize = 400;

  for (;;) {
    const page = await rowsOf(workspaceId, table).limit(pageSize).get();

    if (page.empty) return;

    const batch = db().batch();

    page.docs.forEach((doc) => batch.delete(doc.ref));

    await batch.commit();

    if (page.size < pageSize) return;
  }
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
