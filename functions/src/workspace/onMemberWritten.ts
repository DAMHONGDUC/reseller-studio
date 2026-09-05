import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { db, idSeparator, paths, workspaceOf } from '../lib/firestore';

/**
 * Keeps `users/{uid}.workspaceIds` in step with the membership documents.
 *
 * **This is the only thing that can maintain that list.** `firestore.rules`
 * scopes member reads to one workspace at a time on purpose, so a client has
 * no way to ask "which businesses am I in?" — the app reads the array on its
 * own user document instead, and the workspace switcher renders from it.
 *
 * Without this trigger the array is only ever written by `createWorkspace`,
 * which means a seller sees the businesses they created and **not the ones
 * they were invited to**. That was the gap this closes.
 *
 * **Idempotent**, as every function here must be: `arrayUnion` and
 * `arrayRemove` are set operations, so a retry or a redeploy replaying the
 * event lands on the same array.
 */
export const onMemberWritten = onDocumentWritten(
  'members/{memberId}',
  async (event) => {
    // `{workspaceId}_{uid}`: the workspace is a column, and the uid is what is
    // left of the composite key once the workspace is taken off the front.
    const workspaceId = workspaceOf(event.data);
    const memberId = String(event.params.memberId);
    const memberUid =
      workspaceId === null ? '' : memberId.slice(workspaceId.length + idSeparator.length);

    if (workspaceId === null || memberUid === '') return;

    const existedBefore = event.data?.before.exists ?? false;
    const existsAfter = event.data?.after.exists ?? false;

    // A role change is neither a join nor a leave, and rewriting the array
    // on every edit would be a write per keystroke on the Team screen.
    if (existedBefore === existsAfter) return;

    const user = db().doc(paths.user(memberUid));

    try {
      await user.set(
        {
          workspaceIds: existsAfter
            ? FieldValue.arrayUnion(workspaceId)
            : FieldValue.arrayRemove(workspaceId),
        },
        { merge: true },
      );

      logger.info('workspaceIds updated', {
        workspaceId,
        memberUid,
        joined: existsAfter,
      });
    } catch (error) {
      // Loud on purpose: a swallowed failure here is a seller who cannot see
      // a business they belong to, and nothing else in the system would ever
      // notice. Rethrowing lets the platform retry with backoff.
      logger.error('workspaceIds update failed', {
        workspaceId,
        memberUid,
        joined: existsAfter,
        error,
      });

      throw error;
    }
  },
);
