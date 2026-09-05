import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { workspaceOf } from '../lib/firestore';
import { actionFor, writeActivity } from './writeActivity';

/**
 * The audit log's triggers — one per collection worth logging.
 *
 * **Declared from a list rather than written three times.** Each is the same
 * five lines with a different collection name, and three hand-written copies
 * is how the fourth one ends up logging the wrong `entityType`.
 *
 * Items, orders and listings only: those are the records a teammate changes
 * and another teammate asks about later. Categories and locations are
 * reference data nobody disputes, and logging every keystroke on them would
 * bury the entries that matter.
 */
const logged: ReadonlyArray<{ collection: string; entityType: string }> = [
  { collection: 'items', entityType: 'item' },
  { collection: 'orders', entityType: 'order' },
  { collection: 'listings', entityType: 'listing' },
];

function trigger(collection: string, entityType: string) {
  return onDocumentWritten(
    `${collection}/{entityId}`,
    async (event) => {
      const action = actionFor(event.data);
      // The table is flat, so the workspace is a column rather than a path
      // parameter. A row without one is not a business record and is skipped
      // rather than logged against an empty workspace.
      const workspaceId = workspaceOf(event.data);

      if (action === null || workspaceId === null) return;

      await writeActivity({
        eventId: event.id,
        workspaceId,
        entityType,
        entityId: event.params.entityId,
        action,
        change: event.data,
      });
    },
  );
}

export const onItemWritten = trigger(logged[0].collection, logged[0].entityType);
export const onOrderWritten = trigger(logged[1].collection, logged[1].entityType);
export const onListingWritten = trigger(logged[2].collection, logged[2].entityType);
