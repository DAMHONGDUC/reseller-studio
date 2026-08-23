import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';

/**
 * How recently the caller must have signed in, in seconds.
 *
 * The client used to lean on Firebase's own `requires-recent-login`, which
 * disappears the moment a destructive call moves server-side — the Admin SDK
 * does not ask. This is the same guard, made explicit: a phone left unlocked
 * on a counter must not be one tap away from destroying the business.
 */
const recentSignInSeconds = 5 * 60;

/** Who is calling, or `unauthenticated`. */
export function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in first.');
  }

  return uid;
}

/**
 * Who is calling, refusing a session that has been open too long.
 *
 * **`unauthenticated` rather than `permission-denied` on a stale sign-in**, on
 * purpose: the app maps that code to "sign in again", which is the one thing
 * the seller can actually do about it.
 *
 * Every irreversible call goes through this rather than [requireUid] — today
 * deleting an account and deleting a business, and anything that destroys
 * records from here on.
 */
export function requireFreshUid(request: CallableRequest): string {
  const uid = requireUid(request);
  const authTime = request.auth?.token?.auth_time;
  const staleSignIn =
    typeof authTime !== 'number' ||
    Date.now() / 1000 - authTime > recentSignInSeconds;

  if (staleSignIn) {
    throw new HttpsError('unauthenticated', 'Sign in again, then try that.');
  }

  return uid;
}
