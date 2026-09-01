import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db, paths } from '../lib/firestore';
import { clientFacing } from '../lib/runtime';

/**
 * Remove somebody from a workspace, or change their role.
 *
 * **The last owner cannot be removed or demoted.** That is the check rules
 * cannot make: it needs a count of the owners in the collection, and a rule
 * can read one document. Without it a workspace can be left with nobody able
 * to administer it — and since `canAdmin` decides every other rule, that state
 * is unrecoverable from inside the app.
 *
 * Removing is a delete of the membership document; `onMemberWritten` then
 * takes the workspace out of that person's own list.
 */
export const removeMember = onCall(clientFacing, async (request) => {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in first.');
  }

  const workspaceId = String(request.data?.workspaceId ?? '');
  const memberUid = String(request.data?.memberUid ?? '');
  const nextRole = request.data?.role ? String(request.data.role) : null;

  if (!workspaceId || !memberUid) {
    throw new HttpsError('invalid-argument', 'workspaceId and memberUid are required.');
  }

  const caller = await db().doc(paths.member(workspaceId, uid)).get();
  const callerRole = caller.get('role');

  if (callerRole !== 'owner' && callerRole !== 'admin') {
    throw new HttpsError('permission-denied', 'Only an admin can do that.');
  }

  const targetRef = db().doc(paths.member(workspaceId, memberUid));
  const target = await targetRef.get();

  if (!target.exists) {
    // Idempotent: removing somebody already gone is a success, not an error.
    // A client that lost the answer and retried must not see a failure.
    return { removed: true };
  }

  if (target.get('role') === 'owner' && nextRole !== 'owner') {
    const owners = await db()
      .collection(paths.members(workspaceId))
      .where('role', '==', 'owner')
      .count()
      .get();

    if (owners.data().count <= 1) {
      throw new HttpsError(
        'failed-precondition',
        'A business must keep one owner. Make somebody else owner first.',
      );
    }
  }

  if (nextRole === null) {
    await targetRef.delete();
    logger.info('member removed', { workspaceId });

    return { removed: true };
  }

  await targetRef.set({ role: nextRole }, { merge: true });
  logger.info('member role changed', { workspaceId, role: nextRole });

  return { removed: false };
});
