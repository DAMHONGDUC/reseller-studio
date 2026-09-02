import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { db, paths } from '../lib/firestore';
import { localClock } from '../lib/timezone';
import { expiringOffersFor } from './expiringOffers';
import { notifyWorkspace } from './notify';
import { periodicFor } from './periodicDigest';

/**
 * Hourly, so every workspace can be served at 08:00 in **its own** timezone.
 *
 * A cron expression rather than `every 60 minutes`, which anchors to whenever
 * the deploy happened and would drift the whole fleet off the hour.
 */
const schedule = '0 * * * *';
const timeZone = 'Etc/UTC';

/** The local hour a workspace is digested at. Early enough to be read first. */
const sendAtLocalHour = 8;

/** The default when a workspace has not set its own (`StaleInventoryPolicy`). */
const defaultStaleThresholdDays = 60;

/** The default when a workspace has not set its own (`LowStockPolicy`). */
const defaultLowStockThreshold = 10;

/**
 * How long after posting a marketplace has to pay before it is worth saying.
 *
 * Two weeks: past every platform's normal settlement window, so a run of
 * these is a real gap and not the seller being impatient.
 */
const payoutOverdueDays = 14;

/**
 * How much of the local day is left at 08:00, in hours.
 *
 * The digest fires between 08:00 and 08:59 local (`sendAtLocalHour`), so the
 * rest of the day is the next sixteen hours. Approximate on purpose: naming a
 * window is what "today" means here, and computing a local midnight would need
 * a timezone library for an hour nobody posts in anyway.
 */
const hoursLeftInDay = 16;

/** Statuses where the platform owes the seller but has not obviously paid. */
const awaitingPayoutStatuses = ['shipped', 'delivered'];

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
 * **One send per workspace per local day, keyed by that date**, so a retry, a
 * manual re-run and a redeploy within the same local day all write the same
 * document id and nobody is told twice.
 *
 * **08:00 is the workspace's own 08:00.** The function wakes every hour and
 * digests only the businesses whose wall clock has just reached it, so a
 * seller in California is not woken at 1am by a reminder written for London.
 *
 * **One reminder ignores that gate**: an offer expiring this afternoon is
 * checked on every pass (`expiringOffersFor`), because a sale that walks at
 * 3pm is not helped by a note at 8am tomorrow. It rides this pass rather than
 * scheduling its own, which would re-read every workspace to learn the same
 * thing.
 *
 * The trade to name: this reads every workspace on every run, and there are
 * now twenty-four runs a day rather than one. That is right while there are
 * thousands and wrong at a million, and the fix then is a per-workspace queue
 * rather than a wider query here.
 */
export const dailyDigest = onSchedule({ schedule, timeZone }, async () => {
  const workspaces = await db().collection('workspaces').get();
  const now = new Date();

  let due = 0;
  let sent = 0;

  for (const workspace of workspaces.docs) {
    const settings = workspace.data() ?? {};
    const local = localClock(settings.timezone as string | undefined, now);
    const isDigestHour = local.hour === sendAtLocalHour;

    if (isDigestHour) due += 1;

    try {
      // Every hour, for every business: an offer expiring this afternoon
      // cannot wait for tomorrow's 08:00.
      sent += await expiringOffersFor(workspace.id, now);

      if (isDigestHour) {
        sent += await digestFor(workspace.id, settings, local.day);
        sent += await periodicFor(workspace.id, settings, local);
      }
    } catch (error) {
      // One workspace failing must not cost every workspace after it its
      // reminders — the loop continues and the log names the one that broke.
      logger.error('digest failed', { workspaceId: workspace.id, error });
    }
  }

  logger.info('digest pass complete', {
    workspaces: workspaces.size,
    due,
    sent,
  });
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

  const endOfDay = new Date(now.getTime() + hoursLeftInDay * 60 * 60 * 1000);
  const payoutCutoff = new Date(now);

  payoutCutoff.setDate(payoutCutoff.getDate() - payoutOverdueDays);

  const [due, today, unpaid, stale, onHand] = await Promise.all([
    db()
      .collection(paths.records(workspaceId, 'orders'))
      .where('status', '==', 'toShip')
      .where('shipByDate', '<=', Timestamp.fromDate(now))
      .count()
      .get(),
    // Still in front of the deadline rather than behind it. By the time an
    // order is overdue the platform has already marked it late, which is the
    // thing this reminder exists to prevent.
    db()
      .collection(paths.records(workspaceId, 'orders'))
      .where('status', '==', 'toShip')
      .where('shipByDate', '>', Timestamp.fromDate(now))
      .where('shipByDate', '<=', Timestamp.fromDate(endOfDay))
      .count()
      .get(),
    db()
      .collection(paths.records(workspaceId, 'orders'))
      .where('status', 'in', awaitingPayoutStatuses)
      .where('payoutMinor', '==', null)
      .where('shippedAt', '<=', Timestamp.fromDate(payoutCutoff))
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
  const todayCount = today.data().count;
  const unpaidCount = unpaid.data().count;
  const staleCount = stale.data().count;
  const onHandCount = onHand.data().count;

  let sent = 0;

  if (todayCount > 0) {
    await notifyWorkspace({
      dedupeKey: `shipByToday_${day}`,
      notification: {
        type: 'shipByToday',
        workspaceId,
        count: todayCount,
        route: '/orders/shipping-queue',
        title: 'Going out today',
        body:
          todayCount === 1
            ? '1 order has to go out today.'
            : `${todayCount} orders have to go out today.`,
      },
    });
    sent += 1;
  }

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

  // The only reminder that hands money back rather than work: a payout that
  // never arrived is invisible until somebody goes looking for it.
  if (unpaidCount > 0) {
    await notifyWorkspace({
      dedupeKey: `payoutMissing_${day}`,
      notification: {
        type: 'payoutMissing',
        workspaceId,
        count: unpaidCount,
        route: '/more/payouts',
        title: 'Payout not arrived',
        body:
          unpaidCount === 1
            ? `1 sale has still not been paid out after ${payoutOverdueDays} days.`
            : `${unpaidCount} sales have still not been paid out.`,
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
