import { logger } from 'firebase-functions';

import { ceilingGrace, ceilingsByPlan, db, paths, planFor, rowsOf } from '../lib/firestore';

/** What the workspace is holding, and whether the rules should refuse more. */
export interface WorkspaceUsage {
  items: number;
  orders: number;
  itemsAtCeiling: boolean;
  ordersAtCeiling: boolean;
}

/**
 * Whether a count has run past what its plan allows, with the rules' slack.
 *
 * Pure, and exported so the boundary can be tested without a Firestore — the
 * boundaries are the only interesting part of a limit.
 */
export function atCeiling(plan: string, count: number, kind: 'items' | 'orders'): boolean {
  const ceiling = (ceilingsByPlan[plan] ?? ceilingsByPlan.free)[kind];

  return ceiling !== null && count >= ceiling + ceilingGrace;
}

/**
 * Recount one workspace and write the flags `firestore.rules` reads.
 *
 * **Recounted, never incremented.** Functions are retried — by the platform,
 * by a redeploy — and `FieldValue.increment` is only correct the first time.
 * A recount is idempotent and self-healing: a delivery that was dropped costs
 * nothing, because the next write puts the number right.
 *
 * **Counted with aggregates, not by reading the documents.** A `count()` is
 * billed per index entry rather than per document, so this stays cheap for a
 * seller holding thousands of rows — and it cannot be capped into
 * under-counting the way a bounded document scan would be.
 *
 * The item arithmetic mirrors `countedItemsProvider` in the app: stock on
 * hand, not everything ever typed in. Sold and archived rows are subtracted,
 * and so are soft-deleted ones — a row that is both is subtracted twice,
 * which under-counts, which lets a seller through. That is the direction this
 * has to fail (`docs/rules/BACKEND.md`).
 */
export async function refreshUsage(workspaceId: string): Promise<WorkspaceUsage> {
  const plan = await planFor(workspaceId);
  const items = rowsOf(workspaceId, 'items');
  const orders = rowsOf(workspaceId, 'orders');

  const [total, sold, archived, deleted, orderCount] = await Promise.all([
    items.count().get(),
    items.where('status', '==', 'sold').count().get(),
    items.where('status', '==', 'archived').count().get(),
    items.where('deletedAt', '!=', null).count().get(),
    orders.count().get(),
  ]);

  const onHand = Math.max(
    0,
    total.data().count -
      sold.data().count -
      archived.data().count -
      deleted.data().count,
  );
  const usage: WorkspaceUsage = {
    items: onHand,
    orders: orderCount.data().count,
    itemsAtCeiling: atCeiling(plan, onHand, 'items'),
    ordersAtCeiling: atCeiling(plan, orderCount.data().count, 'orders'),
  };

  await db().doc(paths.usage(workspaceId)).set(usage);

  logger.info('workspace usage recounted', { workspaceId, plan, ...usage });

  return usage;
}
