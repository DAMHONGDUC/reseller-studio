import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import type { Change, DocumentSnapshot } from 'firebase-functions/v2/firestore';

import { db, paths } from '../lib/firestore';

/** What happened to a record. The list is plan §23. */
export type ActivityAction = 'created' | 'updated' | 'deleted';

/**
 * Which way a document went. `deletedAt` appearing is a delete as far as the
 * log is concerned — the app soft-deletes anything another record points at
 * (hard rule 15), so a hard delete is not the only way something goes away.
 */
export function actionFor(change: Change<DocumentSnapshot> | undefined): ActivityAction | null {
  const before = change?.before;
  const after = change?.after;

  if (!before?.exists && after?.exists) return 'created';
  if (before?.exists && !after?.exists) return 'deleted';
  if (!before?.exists || !after?.exists) return null;

  const softDeleted = !before.get('deletedAt') && Boolean(after.get('deletedAt'));

  return softDeleted ? 'deleted' : 'updated';
}

/**
 * Append one entry to a workspace's audit log.
 *
 * **`actorId` is read from the document, never from a client argument.** The
 * whole reason this collection is written here and is `allow create: if false`
 * for everyone else (hard rule 12) is that an entry a client can write can
 * name any actor it likes, which makes the log worthless as a log.
 *
 * **The entry id is the event id**, which is what makes this idempotent: the
 * platform retries triggers, and a log that recorded the same edit three times
 * is a log nobody can reconcile against reality.
 */
export async function writeActivity(options: {
  eventId: string;
  workspaceId: string;
  entityType: string;
  entityId: string;
  action: ActivityAction;
  change: Change<DocumentSnapshot> | undefined;
}): Promise<void> {
  const { eventId, workspaceId, entityType, entityId, action, change } = options;
  const source = action === 'deleted' ? change?.before : change?.after;

  try {
    await db()
      .collection(paths.activity(workspaceId))
      .doc(eventId)
      .create({
        entityType,
        entityId,
        action,
        // `updatedBy` on the edit, falling back to who created the record.
        actorId: source?.get('updatedBy') ?? source?.get('createdBy') ?? null,
        createdAt: FieldValue.serverTimestamp(),
      });
  } catch (error) {
    // `create` on an id that exists throws ALREADY_EXISTS, which is the retry
    // landing twice — the desired outcome, not a failure. Anything else is.
    if ((error as { code?: number }).code === 6) return;

    logger.error('activity write failed', {
      workspaceId,
      entityType,
      entityId,
      action,
      error,
    });

    throw error;
  }
}
