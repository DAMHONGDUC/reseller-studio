import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db, paths } from '../lib/firestore';

/**
 * How recently the caller must have signed in, in seconds.
 *
 * The client used to lean on Firebase's own `requires-recent-login`, which
 * disappears the moment the delete moves server-side — the Admin SDK does not
 * ask. This is the same guard, made explicit: a phone left unlocked on a
 * counter must not be one tap away from destroying the business.
 */
const recentSignInSeconds = 5 * 60;

/** Storage objects are removed a page at a time; the bucket API takes a prefix. */
const storagePrefix = (workspaceId: string) => `workspaces/${workspaceId}/`;

/**
 * Delete the caller's account and everything it owns.
 *
 * **App Store guideline 5.1.1(v) is why this is a function and not a client
 * call.** `user.delete()` removes the login and leaves every document behind,
 * which is not "delete the account and its data" by Apple's reading — and
 * Firestore does not cascade, so the subcollections have to be walked with
 * the Admin SDK.
 *
 * What happens to each business the seller belongs to:
 *
 * - **Sole owner → the workspace goes**, with its subcollections and its
 *   Storage objects. It is their business record; there is nobody to hand it
 *   to, and leaving it would leave an unreachable workspace nobody can
 *   administer (`removeMember` refuses to create that state on purpose).
 * - **Somebody else owns it → only the membership goes.** Deleting a shared
 *   business because one member left would destroy other people's records.
 *
 * The Auth user is deleted **last**: everything above needs the uid, and a
 * failure halfway through leaves an account that can sign in and retry rather
 * than an orphaned login with no data.
 */
export const deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in first.');
  }

  const authTime = request.auth?.token?.auth_time;
  const staleSignIn =
    typeof authTime !== 'number' ||
    Date.now() / 1000 - authTime > recentSignInSeconds;

  if (staleSignIn) {
    // `unauthenticated` on purpose: the app maps it to "sign in again", which
    // is the one thing the seller can actually do about it.
    throw new HttpsError('unauthenticated', 'Sign in again, then delete.');
  }

  const userRef = db().doc(paths.user(uid));
  const userSnap = await userRef.get();
  const workspaceIds: string[] = Array.isArray(userSnap.get('workspaceIds'))
    ? userSnap.get('workspaceIds')
    : [];

  let deleted = 0;
  let left = 0;

  for (const workspaceId of workspaceIds) {
    const members = await db().collection(paths.members(workspaceId)).get();
    const mine = members.docs.find((doc) => doc.id === uid);

    if (!mine) continue;

    const otherOwners = members.docs.filter(
      (doc) => doc.id !== uid && doc.get('role') === 'owner',
    ).length;

    if (mine.get('role') === 'owner' && otherOwners === 0) {
      await db().recursiveDelete(db().doc(paths.workspace(workspaceId)));
      await deleteWorkspaceFiles(workspaceId);
      deleted += 1;
    } else {
      await db().doc(paths.member(workspaceId, uid)).delete();
      left += 1;
    }
  }

  await deletePendingInvites(uid);
  await db().recursiveDelete(userRef);
  await getAuth().deleteUser(uid);

  // Counts, never names — hard rule 9. No email, no workspace name.
  logger.info('account deleted', { workspacesDeleted: deleted, workspacesLeft: left });

  return { workspacesDeleted: deleted, workspacesLeft: left };
});

/**
 * Item photos, receipts and the workspace logo.
 *
 * **A failure here does not fail the delete.** Storage and Firestore are two
 * services, and a bucket that is briefly unavailable must not leave the seller
 * with an account they cannot remove — the log is what makes the leftover
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
 * Invitations addressed to this person that nobody accepted.
 *
 * Keyed by email, so the address has to come from the Auth record rather than
 * from anything the client sent — a client-supplied email here would let one
 * account cancel another's invitations.
 */
async function deletePendingInvites(uid: string): Promise<void> {
  try {
    const user = await getAuth().getUser(uid);
    const email = user.email?.trim().toLowerCase();

    if (!email) return;

    const pending = await db()
      .collection(paths.invites)
      .where('email', '==', email)
      .get();

    await Promise.all(pending.docs.map((doc) => doc.ref.delete()));

    logger.info('pending invites deleted', { count: pending.size });
  } catch (error) {
    logger.error('pending invites not deleted', { error });
  }
}
