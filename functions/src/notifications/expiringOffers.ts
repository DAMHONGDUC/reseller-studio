import { Timestamp } from 'firebase-admin/firestore';

import { db, paths } from '../lib/firestore';
import { notifyWorkspace } from './notify';

/**
 * Offers about to run out.
 *
 * **The only reminder that cannot wait for the morning.** An offer expires in
 * hours, and an expired one is a sale that walked — so this is checked on
 * every pass of the digest's hourly wake-up rather than at 08:00 local.
 *
 * **It rides that same pass rather than scheduling its own**, because the pass
 * already reads every workspace every hour and a second scheduler would read
 * them all again to learn the same thing.
 */

/** How close to the deadline is close enough to be worth a buzz. */
const warnWithinHours = 4;

/**
 * At most one of these per business per hour, whatever is expiring.
 *
 * Three offers closing in the same hour is one line, not three pushes. The
 * hour is the dedupe bucket, so a retried run within it lands on the row it
 * already wrote.
 */
export async function expiringOffersFor(workspaceId: string, now: Date): Promise<number> {
  const deadline = new Date(now.getTime() + warnWithinHours * 60 * 60 * 1000);

  const expiring = await db()
    .collection(paths.records(workspaceId, 'offers'))
    .where('status', '==', 'pending')
    // Still open: an offer whose deadline has passed is the platform's
    // problem now, and telling the seller about it is telling them off.
    .where('expiresAt', '>', Timestamp.fromDate(now))
    .where('expiresAt', '<=', Timestamp.fromDate(deadline))
    .count()
    .get();

  const count = expiring.data().count;

  if (count === 0) return 0;

  await notifyWorkspace({
    dedupeKey: `offerExpiring_${now.toISOString().slice(0, 13)}`,
    notification: {
      type: 'offerExpiring',
      workspaceId,
      count,
      route: '/orders/offers',
      title: 'Offer about to expire',
      body:
        count === 1
          ? `1 offer expires within ${warnWithinHours} hours.`
          : `${count} offers expire within ${warnWithinHours} hours.`,
    },
  });

  return 1;
}
