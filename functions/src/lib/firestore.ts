import { getFirestore } from 'firebase-admin/firestore';

/**
 * The Admin SDK's Firestore handle.
 *
 * Resolved lazily rather than at module load: `index.ts` calls
 * `initializeApp()` and a module that grabbed the handle while being imported
 * would race it.
 */
export const db = () => getFirestore();

/** Paths, in one place, so no function types a collection name twice. */
export const paths = {
  user: (uid: string) => `users/${uid}`,
  workspace: (workspaceId: string) => `workspaces/${workspaceId}`,
  members: (workspaceId: string) => `workspaces/${workspaceId}/members`,
  member: (workspaceId: string, uid: string) =>
    `workspaces/${workspaceId}/members/${uid}`,
  activity: (workspaceId: string) => `workspaces/${workspaceId}/activity`,
  records: (workspaceId: string, collection: string) =>
    `workspaces/${workspaceId}/${collection}`,

  // Both hang off the person, not the business: a device belongs to whoever
  // holds it, and an inbox is addressed to a reader. `users/{uid}` is the one
  // place a client may read without a membership document.
  devices: (uid: string) => `users/${uid}/devices`,
  device: (uid: string, deviceId: string) => `users/${uid}/devices/${deviceId}`,
  notifications: (uid: string) => `users/${uid}/notifications`,
  subscription: (workspaceId: string) =>
    `workspaces/${workspaceId}/subscription/current`,

  // What the workspace is holding, recounted here and read by
  // `firestore.rules`. Its own document rather than a field on the
  // subscription one: that is the webhook's, and two writers on one document
  // is how a late RevenueCat event erases a count.
  usage: (workspaceId: string) => `workspaces/${workspaceId}/usage/current`,
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
