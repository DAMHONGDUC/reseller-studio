import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db, paths, planFor, seatsByPlan } from '../lib/firestore';

/** Roles an invite may grant. `owner` is never handed out by invitation. */
const invitableRoles = ['admin', 'member', 'viewer'];

/**
 * Invite somebody to a workspace by email.
 *
 * **A callable rather than a client write**, because two of the three checks
 * cannot be expressed in `firestore.rules`: counting the members against the
 * seat limit needs an aggregate, and rules cannot aggregate a collection.
 * `invites/` is therefore `allow write: if false`.
 *
 * What it enforces:
 *
 * - the caller is signed in and is an `owner` or `admin` of the workspace;
 * - the plan has a seat left, counting pending invites as taken — otherwise
 *   ten invites sent at once all land and the limit means nothing;
 * - the invitee is not already a member.
 *
 * **Idempotent by construction**: the invite id is derived from the workspace
 * and the email, so inviting the same person twice rewrites one document
 * rather than making a second.
 */
export const inviteMember = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in first.');
  }

  const workspaceId = String(request.data?.workspaceId ?? '');
  const email = String(request.data?.email ?? '')
    .trim()
    .toLowerCase();
  const role = String(request.data?.role ?? 'member');

  if (!workspaceId || !email) {
    throw new HttpsError('invalid-argument', 'workspaceId and email are required.');
  }

  if (!invitableRoles.includes(role)) {
    throw new HttpsError('invalid-argument', 'Unknown role.');
  }

  const [caller, workspace] = await Promise.all([
    db().doc(paths.member(workspaceId, uid)).get(),
    db().doc(paths.workspace(workspaceId)).get(),
  ]);
  const callerRole = caller.get('role');

  if (callerRole !== 'owner' && callerRole !== 'admin') {
    throw new HttpsError('permission-denied', 'Only an admin can invite.');
  }

  const plan = await planFor(workspaceId);
  const seats = seatsByPlan[plan] ?? 1;

  if (seats !== null) {
    const [members, pending] = await Promise.all([
      db().collection(paths.members(workspaceId)).count().get(),
      db()
        .collection(paths.invites)
        .where('workspaceId', '==', workspaceId)
        .where('status', '==', 'pending')
        .count()
        .get(),
    ]);

    const taken = members.data().count + pending.data().count;

    if (taken >= seats) {
      throw new HttpsError(
        'failed-precondition',
        'This plan has no seat left. Upgrade to add teammates.',
      );
    }
  }

  // One document per workspace-and-email, so a repeated invite is an update.
  const inviteId = `${workspaceId}_${Buffer.from(email).toString('hex')}`;

  await db()
    .doc(paths.invite(inviteId))
    .set(
      {
        workspaceId,
        // Denormalised because the invitee cannot read `workspaces/{id}`
        // until they have joined it — without the copy the invitation can
        // only say "a business" and not which one.
        workspaceName: workspace.get('name') ?? null,
        email,
        role,
        status: 'pending',
        invitedBy: uid,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  // The shape, never the contents — hard rule 9. No email in the log line.
  logger.info('invite created', { workspaceId, role, plan });

  return { inviteId };
});
