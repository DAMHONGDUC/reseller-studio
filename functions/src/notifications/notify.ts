import { FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';

import { db, paths, rowsOf } from '../lib/firestore';

/**
 * What a notification is about. The list is plan §22, and the app renders the
 * words from it.
 */
export type NotificationType =
  | 'orderCreated'
  | 'offerReceived'
  | 'shipByToday'
  | 'shipmentsDue'
  | 'offerExpiring'
  | 'payoutMissing'
  | 'profitIncomplete'
  | 'taxSeason'
  | 'restockWinner'
  | 'staleInventory'
  | 'lowInventory'
  | 'memberJoined';

/**
 * How long a read notification is kept, in days.
 *
 * **An inbox nobody prunes is a collection that only grows.** 90 days is long
 * enough that "what happened while I was away" always has an answer, and short
 * enough that a busy seller's inbox does not become the largest collection in
 * their workspace.
 */
const retentionDays = 90;

/** How many expired rows one delivery clears. */
const pruneBatch = 20;

/** One notification, before it is addressed to anybody. */
export interface Notification {
  type: NotificationType;
  workspaceId: string;

  /** What the app should open when it is tapped. A route, never a URL. */
  route: string;

  /** The push text. English only — see the note on [notifyWorkspace]. */
  title: string;
  body: string;

  /** The record it is about, when it is about one. */
  entityId?: string;

  /** How many rows a digest is standing for. Absent when it is about one. */
  count?: number;
}

/**
 * Deliver one notification to every member of a workspace except the actor.
 *
 * **The inbox document is the notification; the push is a copy of it.** A push
 * is best-effort — permission may be off, the token may be stale, the phone
 * may be in a field with no signal — so the Firestore write happens first and
 * is what the seller can always come back to. A design where the push *is* the
 * notification is one where turning off permission silently turns off the
 * feature.
 *
 * **The text is written in English and stored structured.** The function
 * cannot know the reader's locale, so the push carries English (the app ships
 * English until release, hard rule 7) while the inbox row is rendered from
 * `type` and `count` through ARB — which is what lets the translation pass fix
 * the inbox without a backfill.
 *
 * **The actor is skipped.** Nobody needs telling about the order they just
 * typed in, and a push that fires on your own tap is the fastest way to have
 * notifications turned off.
 *
 * **`dedupeKey` is the document id**, so a retried trigger and a digest that
 * runs twice in a day both land on one row rather than three (hard rule: a
 * function that is only correct the first time double-charges).
 *
 * **A mute silences the push and nothing else.** The inbox row is still
 * written for everybody, because the row *is* the notification and the push is
 * a copy of it — dropping the row would make a muted type disappear rather
 * than go quiet, and there would be nothing to come back and read. The mute is
 * per person rather than per business (two people sharing a shop do not want
 * the same reminders) and it is applied here rather than at each caller, so a
 * new notification type cannot forget to check it.
 */
export async function notifyWorkspace(options: {
  dedupeKey: string;
  notification: Notification;
  exceptUid?: string | null;
}): Promise<void> {
  const { dedupeKey, notification, exceptUid } = options;
  const members = await rowsOf(notification.workspaceId, paths.members).get();
  const addressed = members.docs
    .map((doc) => doc.id)
    .filter((uid) => uid !== exceptUid);

  if (addressed.length === 0) return;

  const audible = await listening(addressed, notification.type);

  await Promise.all(addressed.map((uid) => writeInbox(uid, dedupeKey, notification)));
  await Promise.all(audible.map((uid) => push(uid, notification)));
  await Promise.all(addressed.map((uid) => prune(uid)));

  logger.info('notification delivered', {
    type: notification.type,
    workspaceId: notification.workspaceId,
    recipients: addressed.length,
    muted: addressed.length - audible.length,
  });
}

/**
 * Which of [uids] still want their phone to buzz for [type].
 *
 * **Absent means on.** A person who has never opened the notification settings
 * has no preferences field at all, and defaulting that to off would silently
 * mute everybody who upgraded into this build.
 *
 * One `getAll` rather than a read per recipient, and a failure falls back to
 * sending: a preferences lookup that breaks must not swallow the order a
 * seller needs to ship.
 */
async function listening(uids: string[], type: NotificationType): Promise<string[]> {
  try {
    const docs = await db().getAll(...uids.map((uid) => db().doc(paths.user(uid))));

    return docs
      .filter((doc) => (doc.get('notificationPrefs') ?? {})[type] !== false)
      .map((doc) => doc.id);
  } catch (error) {
    logger.error('notification preferences unreadable', { type, error });

    return uids;
  }
}

/**
 * The row the seller opens the app to find.
 *
 * `create` rather than `set`: an id that already exists throws ALREADY_EXISTS,
 * which is the retry landing twice and is the outcome we want, not a failure.
 * Overwriting would resurrect a notification the seller had already read.
 */
async function writeInbox(
  uid: string,
  dedupeKey: string,
  notification: Notification,
): Promise<void> {
  try {
    await db()
      .collection(paths.notifications(uid))
      .doc(dedupeKey)
      .create({
        type: notification.type,
        workspaceId: notification.workspaceId,
        entityId: notification.entityId ?? null,
        count: notification.count ?? null,
        route: notification.route,
        title: notification.title,
        body: notification.body,
        readAt: null,
        createdAt: FieldValue.serverTimestamp(),
      });
  } catch (error) {
    if ((error as { code?: number }).code === 6) return;

    logger.error('notification not written', {
      uid,
      type: notification.type,
      error,
    });

    throw error;
  }
}

/**
 * Drop notifications older than the retention window.
 *
 * **Done here, while this user's inbox is already being written to**, rather
 * than in a scheduled job that walks every user: the work is bounded (one
 * query, at most [pruneBatch] deletes), it costs nothing on an inbox with
 * nothing expired, and it needs no collection-group index.
 *
 * The cap means a long-dormant inbox is trimmed over several deliveries
 * instead of one. That is the intended trade — a delivery must not turn into
 * an unbounded delete.
 *
 * **A failure is logged and swallowed.** Tidying is not worth failing a
 * delivery over, and the platform replaying the trigger would rewrite rows
 * for everybody who already had theirs.
 */
async function prune(uid: string): Promise<void> {
  const cutoff = new Date();

  cutoff.setDate(cutoff.getDate() - retentionDays);

  try {
    const expired = await db()
      .collection(paths.notifications(uid))
      .where('createdAt', '<', cutoff)
      .limit(pruneBatch)
      .get();

    if (expired.empty) return;

    await Promise.all(expired.docs.map((doc) => doc.ref.delete()));

    logger.info('notifications pruned', { uid, count: expired.size });
  } catch (error) {
    logger.error('notifications not pruned', { uid, error });
  }
}

/**
 * The push itself, to every device that person is signed in on.
 *
 * **A failed send is logged and swallowed.** The inbox row is already written,
 * so a dead token must not fail the trigger and have the platform replay it —
 * that would write the row again for everybody else who *did* get theirs.
 */
async function push(uid: string, notification: Notification): Promise<void> {
  try {
    const devices = await db().collection(paths.devices(uid)).get();
    // Docs and tokens are filtered together, so the response at index i is
    // still the device at index i — pruning reads the two as parallel arrays.
    const live = devices.docs.filter((doc) => String(doc.get('token') ?? '').length > 0);
    const tokens = live.map((doc) => String(doc.get('token')));

    if (tokens.length === 0) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: notification.title, body: notification.body },
      // Read by the app on tap. A route, so the deep link cannot point
      // anywhere but at this app (`selleros://` is declared on both
      // platforms).
      data: {
        type: notification.type,
        workspaceId: notification.workspaceId,
        route: notification.route,
      },
    });

    await pruneDeadTokens(uid, live, response.responses);

    logger.info('push sent', {
      uid,
      type: notification.type,
      sent: response.successCount,
      failed: response.failureCount,
    });
  } catch (error) {
    logger.error('push not sent', { uid, type: notification.type, error });
  }
}

/**
 * Forget a token the platform says is gone.
 *
 * An app deleted from a phone leaves its token behind forever otherwise, and
 * every send after that spends a call on a device that cannot receive it.
 */
async function pruneDeadTokens(
  uid: string,
  devices: FirebaseFirestore.QueryDocumentSnapshot[],
  responses: Array<{ success: boolean; error?: { code: string } }>,
): Promise<void> {
  const dead = devices.filter((_, index) => {
    const code = responses[index]?.error?.code;

    return (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    );
  });

  if (dead.length === 0) return;

  await Promise.all(dead.map((doc) => doc.ref.delete()));

  logger.info('dead device tokens removed', { uid, count: dead.length });
}
