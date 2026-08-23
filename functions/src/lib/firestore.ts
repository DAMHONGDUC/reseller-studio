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
  invites: 'invites',
  invite: (inviteId: string) => `invites/${inviteId}`,
};

/**
 * Seats per plan, mirroring `PlanLimits.byPlan` in the app.
 *
 * **This is a deliberate duplicate and the only one.** The limit has to be
 * enforced somewhere a modified client cannot reach, and rules cannot count a
 * collection — so the number exists in Dart for the paywall copy and here for
 * the check. Changing one means changing the other; there is no third place.
 *
 * `null` means unlimited.
 */
export const seatsByPlan: Record<string, number | null> = {
  free: 1,
  pro: 1,
  business: 10,
};

/**
 * Which plan a workspace is on.
 *
 * **A missing subscription document reads as `free`**, which matches the app:
 * with no billing configured every seller reads as Free. Failing the other way
 * would hand out Business seats to anyone whose webhook had not landed yet.
 */
export async function planFor(workspaceId: string): Promise<string> {
  const snap = await db().doc(paths.subscription(workspaceId)).get();
  const plan = snap.get('plan');

  return typeof plan === 'string' && plan in seatsByPlan ? plan : 'free';
}
