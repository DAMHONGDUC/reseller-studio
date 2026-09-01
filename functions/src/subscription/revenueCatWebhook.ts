import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { defineSecret } from 'firebase-functions/params';
import { onRequest } from 'firebase-functions/v2/https';

import { db, paths } from '../lib/firestore';
import { clientFacing } from '../lib/runtime';
import { planFromEvent, willRenew } from './entitlement';
import { refreshUsage } from './usage';

/**
 * The shared token RevenueCat sends in `Authorization`.
 *
 * **Secret Manager, never `env/*.json`** — hard rule 10. The env files are
 * compiled into the Flutter binary and anyone with the `.ipa` can read them;
 * this value is what stops a stranger granting themselves Business by posting
 * a JSON body at a public URL.
 */
const webhookToken = defineSecret('REVENUECAT_WEBHOOK_TOKEN');

/**
 * Mirror RevenueCat's entitlement into Firestore (plan §27).
 *
 * **Until this exists, a plan gate is a UI decision and not a boundary.** The
 * app reads RevenueCat directly, which is a cache for rendering;
 * `firestore.rules` cannot ask an SDK a question, and `inviteMember` counts
 * seats against `planFor(workspaceId)` — which reads the document this
 * function writes. Without it every workspace is Free to the backend however
 * much the seller paid.
 *
 * **The entitlement follows the person; the plan lands on the businesses they
 * own.** RevenueCat knows an `app_user_id`, which this app sets to the
 * Firebase uid at sign-in. A workspace somebody else owns is somebody else's
 * to pay for, so only the ones where this uid is `owner` are written.
 *
 * **Idempotent, and safe out of order.** Deliveries retry and can arrive in
 * any order, so an event older than the one already recorded is dropped
 * rather than applied — otherwise a late RENEWAL would resurrect a lapsed
 * subscription.
 *
 * It answers 200 to anything it understood, including events it deliberately
 * ignores: a non-2xx is a retry, and retrying a `TEST` event forever is noise
 * that hides a real failure.
 */
export const revenueCatWebhook = onRequest(
  { ...clientFacing, secrets: [webhookToken] },
  async (request, response) => {
    if (request.get('Authorization') !== webhookToken.value()) {
      // Never logs what was sent — a wrong token is still a credential.
      logger.warn('revenuecat webhook rejected', { reason: 'bad token' });
      response.status(401).send('Unauthorized');

      return;
    }

    const event = request.body?.event;
    const uid = String(event?.app_user_id ?? '');
    const type = String(event?.type ?? '');

    if (!uid || !type) {
      response.status(400).send('Malformed event');

      return;
    }

    // An anonymous id is a seller who has not signed in on this device yet.
    // There is no workspace to grant anything to, and it is not an error.
    if (uid.startsWith('$RCAnonymousID:')) {
      logger.info('revenuecat event for an anonymous id', { type });
      response.status(200).send('Ignored');

      return;
    }

    try {
      const written = await applyEntitlement(uid, event, type);

      logger.info('revenuecat event applied', { type, workspaces: written });
      response.status(200).send('OK');
    } catch (error) {
      // 500 on purpose: RevenueCat retries with backoff, and a swallowed
      // failure here is a paying seller the backend still reads as Free.
      logger.error('revenuecat event failed', { type, error });
      response.status(500).send('Retry');
    }
  },
);

/** Write the plan onto every workspace this person owns. */
async function applyEntitlement(
  uid: string,
  event: Record<string, unknown>,
  type: string,
): Promise<number> {
  const plan = planFromEvent(event, type);
  const eventTimestampMs = Number(event.event_timestamp_ms ?? Date.now());
  const user = await db().doc(paths.user(uid)).get();
  const workspaceIds: string[] = Array.isArray(user.get('workspaceIds'))
    ? user.get('workspaceIds')
    : [];

  let written = 0;

  for (const workspaceId of workspaceIds) {
    const member = await db().doc(paths.member(workspaceId, uid)).get();

    if (member.get('role') !== 'owner') continue;

    const applied = await writePlan(workspaceId, plan, event, eventTimestampMs);

    if (applied) written += 1;
  }

  return written;
}

/**
 * One workspace's subscription document, unless a newer event already wrote it.
 *
 * Returns whether anything was written, so the log can tell "granted to two
 * businesses" from "dropped as stale".
 */
async function writePlan(
  workspaceId: string,
  plan: string,
  event: Record<string, unknown>,
  eventTimestampMs: number,
): Promise<boolean> {
  const reference = db().doc(paths.subscription(workspaceId));
  const current = await reference.get();
  const seen = Number(current.get('eventTimestampMs') ?? 0);

  if (seen > eventTimestampMs) {
    logger.info('revenuecat event dropped as stale', { workspaceId });

    return false;
  }

  await reference.set(
    {
      plan,
      // The shape, never the receipt (hard rule 9). No transaction id, no
      // token, no price.
      store: String(event.store ?? 'unknown'),
      expiresAtMs: event.expiration_at_ms ?? null,
      willRenew: willRenew(event),
      eventTimestampMs,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  // **Immediately, not on the workspace's next write.** The ceiling flags were
  // computed against the plan that has just changed, so an upgrade would leave
  // a paying seller refused by the rules until they happened to touch a record
  // — a lock-out, and the one failure mode this boundary must not have.
  await refreshUsage(workspaceId);

  return true;
}

