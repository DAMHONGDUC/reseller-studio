import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { db, paths } from '../lib/firestore';
import { refreshUsage } from './usage';

/**
 * Once a day, early, before a seller is likely to be recording anything.
 *
 * UTC because what it recounts is a rolling window rather than anything a
 * business reads off its own clock — unlike the digest, which has to land at
 * 08:00 wherever the seller is.
 */
const schedule = '15 0 * * *';
const timeZone = 'Etc/UTC';

/**
 * Re-count the workspaces the rules are currently refusing writes for.
 *
 * **The order ceiling is a rolling window, and a window empties with the
 * clock rather than with a write.** `onOrderUsageWritten` only recounts when
 * an order is written — and for a workspace at the ceiling, the write that
 * would trigger it is exactly the one being refused. Without this the seller
 * stays walled in after their oldest sale has left the window: a deadlock
 * whose only exit is an action they are not allowed to take.
 *
 * **Only the flagged workspaces are read.** One below its ceiling cannot
 * become blocked without a write, and a write recounts it; so the set that
 * can go stale in the blocking direction is exactly the set flagged now.
 * `usage` is a flat top-level collection keyed by workspace id, so this is one
 * query however many businesses exist.
 */
export const refreshUsageDaily = onSchedule({ schedule, timeZone }, async () => {
  const blocked = await db()
    .collection('usage')
    .where('ordersAtCeiling', '==', true)
    .get();

  let cleared = 0;

  for (const row of blocked.docs) {
    try {
      const usage = await refreshUsage(row.id);

      if (!usage.ordersAtCeiling) cleared += 1;
    } catch (error) {
      // One workspace failing must not stop the rest: the next run picks it
      // up again, and a thrown scheduler run leaves every later workspace
      // blocked for another day.
      logger.error('usage recount failed', {
        workspaceId: row.id,
        path: paths.usage(row.id),
        error,
      });
    }
  }

  logger.info('rolling order windows recounted', {
    checked: blocked.size,
    cleared,
  });
});
