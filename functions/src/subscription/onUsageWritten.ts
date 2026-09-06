import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { workspaceOf } from '../lib/firestore';
import { refreshUsage } from './usage';

/**
 * Keep `usage/{workspaceId}` in step with what the workspace holds.
 *
 * **This is what makes the Free ceilings a boundary rather than a UI
 * decision** (plan §27). `firestore.rules` cannot aggregate a collection, so
 * it cannot count anything — it can only read one document. This writes the
 * document it reads.
 *
 * **Deliberately separate from the audit-log triggers on the same paths.**
 * They answer different questions and fail independently: an audit entry that
 * could not be written must not also leave the ceiling unenforced, and a
 * recount that threw must not lose the entry that says who changed what.
 *
 * Listings are not counted — no plan limits them.
 */
function trigger(collection: string) {
  return onDocumentWritten(`${collection}/{entityId}`, (event) => {
    // Flat tables: the workspace is a column now, not a path parameter.
    const workspaceId = workspaceOf(event.data);

    return workspaceId === null ? undefined : refreshUsage(workspaceId);
  });
}

export const onItemUsageWritten = trigger('items');
export const onOrderUsageWritten = trigger('orders');
