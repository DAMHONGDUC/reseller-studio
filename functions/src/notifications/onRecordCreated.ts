import { onDocumentCreated } from 'firebase-functions/v2/firestore';

import { idSeparator, workspaceOf } from '../lib/firestore';
import { notifyWorkspace } from './notify';

/** A record's own id, out of the composite key it is stored under. */
function localId(workspaceId: string | null, rowId: string): string {
  return workspaceId === null ? '' : rowId.slice(workspaceId.length + idSeparator.length);
}

/**
 * The two notifications that come from a record appearing (plan §22).
 *
 * **Created, not written.** A new order is news; an edited one is not, and a
 * trigger on writes would push every time somebody corrected a fee. The
 * reminders that *are* about a record sitting too long are the scheduled
 * digest instead.
 *
 * **The dedupe key is the event id**, so the platform replaying a trigger
 * lands on the row it already wrote rather than a second one.
 */
export const onOrderCreated = onDocumentCreated(
  'orders/{rowId}',
  async (event) => {
    // Flat tables: the workspace is a column, and the record's own id is what
    // is left of the composite key `{workspaceId}_{orderId}`.
    const workspaceId = workspaceOf({ after: event.data });
    const orderId = localId(workspaceId, String(event.params.rowId));

    if (workspaceId === null || orderId === '') return;

    // The line items are embedded (`docs/DATA_MODEL.md`), and `get()` cannot
    // index into an array — so the array is read whole and the first line's
    // title is what names the push.
    const lines = event.data?.get('lines');
    const title = Array.isArray(lines) ? String(lines[0]?.title ?? '') : '';

    await notifyWorkspace({
      dedupeKey: event.id,
      exceptUid: event.data?.get('createdBy') ?? null,
      notification: {
        type: 'orderCreated',
        workspaceId,
        entityId: orderId,
        route: `/orders/${orderId}`,
        title: 'New order',
        // The buyer is never named — hard rule 9 keeps addresses and names
        // out of anything that leaves the backend.
        body: title ? `Sold: ${title}` : 'You have a new order to ship.',
      },
    });
  },
);

export const onOfferCreated = onDocumentCreated(
  'offers/{rowId}',
  async (event) => {
    const workspaceId = workspaceOf({ after: event.data });
    const offerId = localId(workspaceId, String(event.params.rowId));

    if (workspaceId === null || offerId === '') return;


    await notifyWorkspace({
      dedupeKey: event.id,
      exceptUid: event.data?.get('createdBy') ?? null,
      notification: {
        type: 'offerReceived',
        workspaceId,
        entityId: offerId,
        route: '/orders/offers',
        title: 'New offer',
        body: 'A buyer has made an offer. It expires — take a look.',
      },
    });
  },
);

/**
 * Somebody joined the business (plan §22's "team activity").
 *
 * On the membership document rather than inside `acceptInvite`, so a member
 * added any other way — a future transfer, a repair script — is announced too.
 */
export const onMemberJoined = onDocumentCreated(
  'members/{memberId}',
  async (event) => {
    const workspaceId = workspaceOf({ after: event.data });
    const memberUid = localId(workspaceId, String(event.params.memberId));
    const name = String(event.data?.get('displayName') ?? '').trim();

    if (workspaceId === null || memberUid === '') return;

    await notifyWorkspace({
      dedupeKey: event.id,
      // The person who just joined does not need telling that they did.
      exceptUid: memberUid,
      notification: {
        type: 'memberJoined',
        workspaceId,
        entityId: memberUid,
        route: '/more/team',
        title: 'New teammate',
        // The name is already denormalised onto the membership document the
        // whole team can read, so it is not a disclosure — an email would be.
        body: name ? `${name} joined the business.` : 'Somebody joined the business.',
      },
    });
  },
);
