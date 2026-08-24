import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { db, paths } from '../lib/firestore';
import { notifyWorkspace } from './notify';

/** When it runs. Early enough to be the first thing read, in one timezone. */
const schedule = 'every day 08:00';
const timeZone = 'Etc/UTC';

/** The default when a workspace has not set its own (`StaleInventoryPolicy`). */
const defaultStaleThresholdDays = 60;

/** The default when a workspace has not set its own (`LowStockPolicy`). */
const defaultLowStockThreshold = 10;

/**
 * Item statuses that count as stock the seller still owns.
 *
 * Mirrors `ItemStatus.isOnHand` in the app — `sold` and `archived` are out,
 * because neither is on the shelf and counting them would tell a seller they
 * have stock they have already parted with.
 */
const onHandStatuses = ['draft', 'inStock', 'listed', 'reserved'];

/**
 * The reminders that are about a record *sitting*, not about one appearing
 * (plan §22: order reminder, shipping reminder, stale inventory).
 *
 * **A digest, not one push per row.** Forty stale listings is one line — "40
 * listings have been up over 60 days" — because a seller who gets forty
 * notifications turns notifications off, and the app's whole promise is to
 * tell them what needs attention *today* rather than to enumerate it.
 *
 * **One send per workspace per day, keyed by the date**, so a retry, a manual
 * re-run and a redeploy on the same day all write the same document id and
 * nobody is told twice.
 *
 * The trade to name: this reads every workspace on every run. That is right
 * while there are thousands and wrong at a million, and the fix then is a
 * per-workspace queue rather than a wider query here.
 */
export const dailyDigest = onSchedule({ schedule, timeZone }, async () => {
  const workspaces = await db().collection('workspaces').get();
  const day = new Date().toISOString().slice(0, 10);

  let sent = 0;

  for (const workspace of workspaces.docs) {
    try {
      sent += await digestFor(workspace.id, workspace.data() ?? {}, day);
    } catch (error) {
      // One workspace failing must not cost every workspace after it its
      // reminders — the loop continues and the log names the one that broke.
      logger.error('digest failed', { workspaceId: workspace.id, error });
    }
  }

  logger.info('daily digest complete', { workspaces: workspaces.size, sent });
});

/** Every count for one business, and at most one notification each. */
async function digestFor(
  workspaceId: string,
  settings: FirebaseFirestore.DocumentData,
  day: string,
): Promise<number> {
  const now = new Date();
  const staleBefore = new Date(now);
  const lowStockThreshold =
    typeof settings.lowStockThreshold === 'number'
      ? settings.lowStockThreshold
      : defaultLowStockThreshold;

  staleBefore.setDate(
    staleBefore.getDate() -
      (typeof settings.staleThresholdDays === 'number'
        ? settings.staleThresholdDays
        : defaultStaleThresholdDays),
  );

  const [due, stale, onHand] = await Promise.all([
    db()
      .collection(paths.records(workspaceId, 'orders'))
      .where('status', '==', 'toShip')
      .where('shipByDate', '<=', Timestamp.fromDate(now))
      .count()
      .get(),
    db()
      .collection(paths.records(workspaceId, 'items'))
      .where('status', '==', 'listed')
      .where('listedAt', '<=', Timestamp.fromDate(staleBefore))
      .count()
      .get(),
    db()
      .collection(paths.records(workspaceId, 'items'))
      .where('status', 'in', onHandStatuses)
      .count()
      .get(),
  ]);

  const dueCount = due.data().count;
  const staleCount = stale.data().count;
  const onHandCount = onHand.data().count;

  let sent = 0;

  if (dueCount > 0) {
    await notifyWorkspace({
      dedupeKey: `shipmentsDue_${day}`,
      notification: {
        type: 'shipmentsDue',
        workspaceId,
        count: dueCount,
        route: '/orders/shipping-queue',
        title: 'Orders to ship',
        body:
          dueCount === 1
            ? '1 order is past its ship-by date.'
            : `${dueCount} orders are past their ship-by date.`,
      },
    });
    sent += 1;
  }

  if (staleCount > 0) {
    await notifyWorkspace({
      dedupeKey: `staleInventory_${day}`,
      notification: {
        type: 'staleInventory',
        workspaceId,
        count: staleCount,
        route: '/inventory',
        title: 'Stale listings',
        body:
          staleCount === 1
            ? '1 listing has been up a long time. Reprice it?'
            : `${staleCount} listings have been up a long time. Reprice them?`,
      },
    });
    sent += 1;
  }

  // **Only when there is something left to sell.** An empty workspace is a
  // new one, and telling somebody who has nothing that they have nothing is
  // the notification that gets notifications turned off.
  if (onHandCount > 0 && onHandCount < lowStockThreshold) {
    await notifyWorkspace({
      dedupeKey: `lowInventory_${day}`,
      notification: {
        type: 'lowInventory',
        workspaceId,
        count: onHandCount,
        route: '/more/sourcing',
        title: 'Running low',
        body:
          onHandCount === 1
            ? 'Only 1 item left in stock. Time to source.'
            : `Only ${onHandCount} items left in stock. Time to source.`,
      },
    });
    sent += 1;
  }

  return sent;
}
