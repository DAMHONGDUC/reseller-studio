import { logger } from 'firebase-functions';

import { db, idSeparator, paths, workspaceField, workspaceTables } from '../lib/firestore';

/**
 * Move every nested record into its flat table (hard rule 14).
 *
 * `workspaces/{id}/items/{itemId}` becomes `items/{id}_{itemId}` carrying a
 * `workspaceId` column, which is the shape the app and the rules read after
 * the migration. Run it once per project, before deploying the new rules.
 *
 * **Copy, then delete — never a move.** A run that dies halfway leaves the
 * nested rows intact and the flat ones already written, so the next run
 * finishes rather than losing what it was carrying. That is also what makes
 * the second half opt-in: read the flat tables, satisfy yourself, then sweep.
 *
 * **Idempotent.** Every write is a `set` at a deterministic id, so a row that
 * is already flat is rewritten to the same value rather than duplicated.
 *
 * `subscription/current` and `usage/current` are keyed by the workspace id
 * itself rather than a composite, because there is exactly one of each per
 * business — see `paths.subscription` and `paths.usage`.
 */
export async function flattenTables(options: {
  deleteNested: boolean;
}): Promise<{ workspaces: number; rows: number }> {
  const workspaces = await db().collection('workspaces').get();
  let rows = 0;

  for (const workspace of workspaces.docs) {
    for (const table of workspaceTables) {
      rows += await copyTable(workspace.id, table, options.deleteNested);
    }

    rows += await copySingleton(workspace.id, 'subscription', paths.subscription(workspace.id), options.deleteNested);
    rows += await copySingleton(workspace.id, 'usage', paths.usage(workspace.id), options.deleteNested);
  }

  logger.info('flatten complete', { workspaces: workspaces.size, rows });

  return { workspaces: workspaces.size, rows };
}

/**
 * One nested subcollection into its flat table, a page at a time.
 *
 * Paged because a seller with thousands of items would otherwise be read whole
 * into memory, and a batch caps at 500 writes.
 */
async function copyTable(
  workspaceId: string,
  table: string,
  deleteNested: boolean,
): Promise<number> {
  const pageSize = 300;
  let moved = 0;
  let cursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;

  for (;;) {
    let query = db()
      .collection(`workspaces/${workspaceId}/${table}`)
      .orderBy('__name__')
      .limit(pageSize);

    if (cursor) query = query.startAfter(cursor);

    const page = await query.get();

    if (page.empty) return moved;

    const batch = db().batch();

    for (const doc of page.docs) {
      batch.set(db().doc(`${table}/${workspaceId}${idSeparator}${doc.id}`), {
        ...doc.data(),
        [workspaceField]: workspaceId,
      });

      if (deleteNested) batch.delete(doc.ref);
    }

    await batch.commit();

    moved += page.size;
    cursor = page.docs[page.docs.length - 1];

    if (page.size < pageSize) return moved;
  }
}

/** The one-document subcollections, keyed by the workspace id itself. */
async function copySingleton(
  workspaceId: string,
  table: string,
  target: string,
  deleteNested: boolean,
): Promise<number> {
  const source = db().doc(`workspaces/${workspaceId}/${table}/current`);
  const doc = await source.get();

  if (!doc.exists) return 0;

  await db().doc(target).set({ ...doc.data(), [workspaceField]: workspaceId });

  if (deleteNested) await source.delete();

  return 1;
}
