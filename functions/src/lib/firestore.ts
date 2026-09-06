import { getFirestore } from 'firebase-admin/firestore';

/**
 * The Admin SDK's Firestore handle.
 *
 * Resolved lazily rather than at module load: `index.ts` calls
 * `initializeApp()` and a module that grabbed the handle while being imported
 * would race it.
 */
export const db = () => getFirestore();

/** What joins a workspace id to a record id in a composite document id. */
export const idSeparator = '_';

/** The column every business row carries, and the whole security boundary. */
export const workspaceField = 'workspaceId';

/**
 * Every business table, for anything that has to sweep all of them.
 *
 * **A flat table has no parent to delete**, so the `recursiveDelete` the
 * nested model got for free is now this list plus a query each. Adding a table
 * means adding it here, or a deleted business leaves rows behind. It mirrors
 * `WorkspaceCollections.tableNames` in the app.
 */
export const workspaceTables = [
  'members',
  'items',
  'listings',
  'orders',
  'offers',
  'purchases',
  'sources',
  'expenses',
  'categories',
  'locations',
  'marketplaces',
  'carriers',
  'receipts',
  'activity',
];

/**
 * Every row one workspace owns in one table, already filtered.
 *
 * **The only way this codebase reads a business table**, so a query here
 * cannot forget the `workspaceId` filter any more than the app's
 * `WorkspaceTable.query` can. Writing a row still goes through
 * `db().collection(table).doc(id)`, which is by id and needs no filter.
 */
export function rowsOf(workspaceId: string, table: string) {
  return db().collection(table).where(workspaceField, '==', workspaceId);
}

/**
 * The workspace a written row belongs to, read from the row itself.
 *
 * **Triggers can no longer take it from the path.** The tables are flat (hard
 * rule 14), so `workspaces/{workspaceId}/items/{id}` became `items/{id}` and
 * the id that used to be a path parameter is a column. Reads `after` first and
 * falls back to `before`, so a delete still names its workspace.
 */
export function workspaceOf(change: {
  before?: { get(field: string): unknown };
  after?: { get(field: string): unknown };
} | undefined): string | null {
  const value = change?.after?.get(workspaceField) ?? change?.before?.get(workspaceField);

  return typeof value === 'string' && value !== '' ? value : null;
}

/** Paths, in one place, so no function types a collection name twice. */
export const paths = {
  user: (uid: string) => `users/${uid}`,
  workspace: (workspaceId: string) => `workspaces/${workspaceId}`,

  // **Every business table is flat and top-level** (hard rule 14), each row
  // carrying a `workspaceId` column, so a table is named without a workspace
  // and the workspace arrives as a `where` instead. `rowsOf` is the only way
  // this file reads one, so no query here can forget the filter either.
  table: (collection: string) => collection,
  members: 'members',
  activity: 'activity',

  // A membership is keyed `{workspaceId}_{uid}` — a composite primary key,
  // because one person belongs to several businesses. **The separator matches
  // `WorkspaceTable.idSeparator` in the app and `memberDocId` in
  // `firestore.rules`**; three spellings of one key is how a membership
  // becomes unreadable to the rule that decides every other permission.
  member: (workspaceId: string, uid: string) =>
    `members/${workspaceId}${idSeparator}${uid}`,

  /** One row by its local id, under the composite key it is stored at. */
  row: (table: string, workspaceId: string, id: string) =>
    `${table}/${workspaceId}${idSeparator}${id}`,

  // Both hang off the person, not the business: a device belongs to whoever
  // holds it, and an inbox is addressed to a reader. `users/{uid}` is the one
  // place a client may read without a membership document.
  devices: (uid: string) => `users/${uid}/devices`,
  device: (uid: string, deviceId: string) => `users/${uid}/devices/${deviceId}`,
  notifications: (uid: string) => `users/${uid}/notifications`,
  subscription: (workspaceId: string) => `subscription/${workspaceId}`,

  // What the workspace is holding, recounted here and read by
  // `firestore.rules`. Its own document rather than a field on the
  // subscription one: that is the webhook's, and two writers on one document
  // is how a late RevenueCat event erases a count.
  usage: (workspaceId: string) => `usage/${workspaceId}`,
  invites: 'invites',
  invite: (inviteId: string) => `invites/${inviteId}`,
};

/**
 * Team seats per plan.
 *
 * The callable enforces this where a modified client cannot reach. It is
 * separate from the Inventory, Order, and business ceilings in `PlanLimits`.
 *
 * `null` means unlimited.
 */
export const seatsByPlan: Record<string, number | null> = {
  free: 1,
  premium: 10,
};

/**
 * Items on hand and orders per plan — the ceilings `PlanLimits.byPlan` states
 * for the app.
 *
 * A deliberate duplicate for the same reason `seatsByPlan` is one: the app
 * needs the numbers to render the paywall, and the backend needs them where a
 * modified client cannot reach. **Changing one means changing the other.**
 *
 * `null` means unlimited.
 */
export const ceilingsByPlan: Record<string, { items: number | null; orders: number | null }> = {
  // **Free counts records, and these two numbers are the mirror.** They must
  // equal `PlanLimits.byPlan[SellerPlan.free]` in the app; a plan with nothing
  // to count also has nothing to show, which is why the ceilings came back.
  // Premium still sells the answers — `PlanFeature.taxExport`,
  // `payoutReconciliation`, `advancedAnalytics`, `team`.
  free: { items: 50, orders: 30 },
  premium: { items: null, orders: null },
};

/**
 * How far past a ceiling the *rules* let a client go before refusing.
 *
 * **The client gate is the ceiling on use; the rule is the ceiling on abuse.**
 * The count a rule reads is recounted by a trigger, so it lags a write by a
 * second or two — without slack, a seller at the ceiling who deletes a row and
 * immediately adds one would be refused by the backend for an action their own
 * app had just allowed. That is a lock-out (`docs/rules/BACKEND.md`), and the
 * whole point of this boundary is the client that ignores its gate entirely,
 * which slack does nothing for.
 */
export const ceilingGrace = 10;

/**
 * Which plan a workspace is on.
 *
 * **A missing subscription document reads as `free`**, which matches the app:
 * with no billing configured every seller reads as Free. Failing the other way
 * would hand out Premium seats to anyone whose webhook had not landed yet.
 */
export async function planFor(workspaceId: string): Promise<string> {
  const snap = await db().doc(paths.subscription(workspaceId)).get();
  const plan = snap.get('plan');

  return typeof plan === 'string' && plan in seatsByPlan ? plan : 'free';
}
