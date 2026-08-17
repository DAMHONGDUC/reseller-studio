import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db, paths } from '../lib/firestore';

/**
 * Turn a pending invite into a membership.
 *
 * **The invitee cannot write their own membership document** — hard rule 11
 * says nobody edits their own, and the rules only exempt the very first owner
 * of a new workspace. So joining a team has to happen here.
 *
 * The email on the invite is matched against the **verified token**, not
 * against anything the client sent: an invite is addressed to a person, and
 * trusting a client-supplied address would let anyone claim any invite.
 *
 * **Idempotent**: accepting twice writes the same membership and leaves the
 * invite `accepted` either way. `onMemberWritten` then adds the workspace to
 * the user's own list.
 */
export const acceptInvite = onCall(async (request) => {
  const uid = request.auth?.uid;
  const tokenEmail = request.auth?.token.email?.toLowerCase();

  if (!uid || !tokenEmail) {
    throw new HttpsError('unauthenticated', 'Sign in first.');
  }

  const inviteId = String(request.data?.inviteId ?? '');

  if (!inviteId) {
    throw new HttpsError('invalid-argument', 'inviteId is required.');
  }

  const inviteRef = db().doc(paths.invite(inviteId));
  const invite = await inviteRef.get();

  if (!invite.exists) {
    throw new HttpsError('not-found', 'That invitation no longer exists.');
  }

  const email = String(invite.get('email') ?? '').toLowerCase();
  const workspaceId = String(invite.get('workspaceId') ?? '');
  const role = String(invite.get('role') ?? 'member');
  const status = String(invite.get('status') ?? '');

  if (email !== tokenEmail) {
    // Deliberately the same error a missing invite gives: telling a caller
    // that an invite exists but is not theirs confirms an address.
    throw new HttpsError('not-found', 'That invitation no longer exists.');
  }

  if (status !== 'pending' && status !== 'accepted') {
    throw new HttpsError('failed-precondition', 'That invitation is no longer open.');
  }

  const batch = db().batch();

  batch.set(
    db().doc(paths.member(workspaceId, uid)),
    {
      role,
      // Denormalised so the Team screen renders without reading anyone
      // else's user document, which the rules forbid (`docs/DATA_MODEL.md`).
      displayName: request.auth?.token.name ?? null,
      email: tokenEmail,
      joinedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  batch.set(
    inviteRef,
    { status: 'accepted', acceptedBy: uid, acceptedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );

  await batch.commit();

  logger.info('invite accepted', { workspaceId, role });

  return { workspaceId };
});
