import { Timestamp } from 'firebase-admin/firestore';

import { db, paths } from '../lib/firestore';
import { LocalClock } from '../lib/timezone';
import { notifyWorkspace } from './notify';

/**
 * The reminders that are not daily — weekly bookkeeping, a monthly sourcing
 * note, and the two dates a year the tax figures matter.
 *
 * **They ride the daily digest's pass rather than scheduling their own.** That
 * pass already wakes hourly and already knows which businesses have just
 * reached 08:00 local, so a second scheduler would re-read every workspace to
 * learn the same thing — and would need its own answer to what a local Monday
 * is.
 */

/** Order statuses whose money counts — mirrors `OrderStatus.countsAsRevenue`. */
const revenueStatuses = ['toShip', 'shipped', 'delivered', 'returnRequested', 'returned'];

/** The local weekday the bookkeeping nudge lands on. 1 is Monday. */
const bookkeepingWeekday = 1;

/** Firestore's cap on a single `getAll`, and the cap on one month's join. */
const readChunk = 300;

/**
 * How many of last month's orders the sourcing note will read.
 *
 * A bound rather than a promise: a business selling more than this a month is
 * one whose winning source is obvious to them already, and an unbounded
 * monthly join is the kind of job that is fine until the day it is not.
 */
const monthlyOrderCap = 500;

/**
 * When each country's figures matter, as local month/day pairs.
 *
 * **Country-specific by design** — the launch markets are the US and the UK
 * and their tax years do not line up (root `CLAUDE.md`). A third country is
 * another entry here, never a widened `if` at a call site.
 */
const taxMilestones: Record<string, { month: number; day: number; note: string }[]> = {
  us: [
    { month: 1, day: 5, note: 'Your tax year has closed. Your figures are ready to export.' },
    { month: 4, day: 1, note: 'Two weeks to the filing deadline. Your figures are ready to export.' },
  ],
  uk: [
    { month: 1, day: 10, note: 'Three weeks to the Self Assessment deadline. Your figures are ready to export.' },
    { month: 4, day: 10, note: 'Your tax year has closed. Your figures are ready to export.' },
  ],
};

/** Every non-daily reminder for one business, at its own 08:00. */
export async function periodicFor(
  workspaceId: string,
  settings: FirebaseFirestore.DocumentData,
  local: LocalClock,
): Promise<number> {
  const date = new Date(`${local.day}T00:00:00Z`);

  let sent = 0;

  // `getUTCDay` on a date built from the local calendar string: the string is
  // already the local day, so the weekday is the local one.
  if (date.getUTCDay() === bookkeepingWeekday) {
    sent += await bookkeeping(workspaceId, local.day);
  }

  if (date.getUTCDate() === 1) {
    sent += await sourcingNote(workspaceId, date);
  }

  sent += await taxSeason(workspaceId, settings, date, local.day);

  return sent;
}

/**
 * Sales whose platform fee is still the published estimate.
 *
 * **The fee, not the cost.** A missing fee is one queryable field, and since
 * `Order.effectiveFees` it is exactly the set whose profit is an estimate —
 * a missing item cost lives inside the embedded lines, which Firestore cannot
 * query into at all.
 */
async function bookkeeping(workspaceId: string, day: string): Promise<number> {
  const estimated = await db()
    .collection(paths.records(workspaceId, 'orders'))
    .where('status', 'in', revenueStatuses)
    .where('feesMinor', '==', null)
    .count()
    .get();

  const count = estimated.data().count;

  if (count === 0) return 0;

  await notifyWorkspace({
    dedupeKey: `profitIncomplete_${day}`,
    notification: {
      type: 'profitIncomplete',
      workspaceId,
      count,
      route: '/more/books',
      title: 'Fees still estimated',
      body:
        count === 1
          ? '1 sale still has an estimated fee. Enter the real one and your profit is exact.'
          : `${count} sales still have an estimated fee. Enter the real ones and your profit is exact.`,
    },
  });

  return 1;
}

/**
 * Which source actually sold last month — the plan's own last step,
 * ANALYZE → SOURCE BETTER.
 *
 * The join is orders → items → source, because an order names items and only
 * an item knows where it was bought. Bounded by [monthlyOrderCap] and read
 * once a month.
 */
async function sourcingNote(workspaceId: string, firstOfMonth: Date): Promise<number> {
  const from = new Date(firstOfMonth);

  from.setUTCMonth(from.getUTCMonth() - 1);

  const orders = await db()
    .collection(paths.records(workspaceId, 'orders'))
    .where('status', 'in', revenueStatuses)
    .where('orderedAt', '>=', Timestamp.fromDate(from))
    .where('orderedAt', '<', Timestamp.fromDate(firstOfMonth))
    .limit(monthlyOrderCap)
    .get();

  if (orders.empty) return 0;

  const revenueByItem = new Map<string, number>();

  for (const order of orders.docs) {
    const lines = order.get('lines');

    if (!Array.isArray(lines)) continue;

    for (const line of lines) {
      const itemId = String(line?.itemId ?? '');

      if (itemId.length === 0) continue;

      const value = Number(line?.unitPriceMinor ?? 0) * Number(line?.quantity ?? 1);

      revenueByItem.set(itemId, (revenueByItem.get(itemId) ?? 0) + value);
    }
  }

  const revenueBySource = await groupBySource(workspaceId, revenueByItem);
  const winner = [...revenueBySource.entries()].sort((a, b) => b[1] - a[1])[0];

  // One source is not a comparison. The note is "this one beat the others",
  // and with nothing to beat it says nothing.
  if (winner === undefined || revenueBySource.size < 2) return 0;

  const source = await db().doc(`${paths.records(workspaceId, 'sources')}/${winner[0]}`).get();
  const name = String(source.get('name') ?? '');

  if (name.length === 0) return 0;

  await notifyWorkspace({
    dedupeKey: `restockWinner_${firstOfMonth.toISOString().slice(0, 7)}`,
    notification: {
      type: 'restockWinner',
      workspaceId,
      entityId: winner[0],
      route: '/analytics/sources',
      title: 'Worth buying again',
      body: `${name} sold more than any other source last month.`,
    },
  });

  return 1;
}

/** Fold per-item revenue onto the source each item was bought from. */
async function groupBySource(
  workspaceId: string,
  revenueByItem: Map<string, number>,
): Promise<Map<string, number>> {
  const ids = [...revenueByItem.keys()].slice(0, monthlyOrderCap);
  const revenueBySource = new Map<string, number>();

  for (let offset = 0; offset < ids.length; offset += readChunk) {
    const chunk = ids.slice(offset, offset + readChunk);
    const items = await db().getAll(
      ...chunk.map((id) => db().doc(`${paths.records(workspaceId, 'items')}/${id}`)),
    );

    for (const item of items) {
      const sourceId = String(item.get('sourceId') ?? '');

      // An item bought before the seller recorded a source is not evidence
      // about any source, so it is left out rather than lumped into "none".
      if (sourceId.length === 0) continue;

      const revenue = revenueByItem.get(item.id) ?? 0;

      revenueBySource.set(sourceId, (revenueBySource.get(sourceId) ?? 0) + revenue);
    }
  }

  return revenueBySource;
}

/** The two dates a year this business's figures are due. */
async function taxSeason(
  workspaceId: string,
  settings: FirebaseFirestore.DocumentData,
  date: Date,
  day: string,
): Promise<number> {
  const country = String(settings.country ?? '').toLowerCase();
  const milestones = taxMilestones[country];

  // A country with no rules written is told nothing rather than told the
  // wrong country's dates.
  if (milestones === undefined) return 0;

  const today = milestones.find(
    (milestone) =>
      milestone.month === date.getUTCMonth() + 1 && milestone.day === date.getUTCDate(),
  );

  if (today === undefined) return 0;

  await notifyWorkspace({
    dedupeKey: `taxSeason_${day}`,
    notification: {
      type: 'taxSeason',
      workspaceId,
      route: '/more/tax',
      title: 'Tax deadline',
      body: today.note,
    },
  });

  return 1;
}
