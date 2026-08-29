import { seatsByPlan } from '../lib/firestore';

/**
 * Entitlement identifier → plan, mirroring the RevenueCat entitlement passed
 * to the Flutter build through `AppEnv`.
 *
 * A second deliberate duplicate, for the same reason `seatsByPlan` is one:
 * the app needs it to render the paywall and the backend needs it where a
 * modified client cannot reach. Changing one means changing the other.
 */
export const planByEntitlement: Record<string, string> = {
  premium: 'premium',
};

/** Cheapest first, so "the highest entitlement the seller holds" is a max. */
const planRank = ['free', 'premium'];

/**
 * Which plan a RevenueCat event leaves the seller on.
 *
 * **Computed from the entitlements and the expiry, not from the event type.**
 * A CANCELLATION does not end access — the seller keeps what they paid for
 * until the period runs out — and a switch on the type is how that becomes an
 * instant downgrade the day somebody taps "cancel" on the last day of a year.
 *
 * An entitlement this build does not know maps to nothing rather than to the
 * neighbour it sits next to, so a tier added to the dashboard first reads as
 * Free until the two lists agree again.
 *
 * Pure, and in its own module so it can be tested without a Firestore.
 */
export function planFromEvent(
  event: Record<string, unknown>,
  type: string,
  now: number = Date.now(),
): string {
  const expiresAtMs = Number(event.expiration_at_ms ?? 0);
  const expired = type === 'EXPIRATION' || (expiresAtMs > 0 && expiresAtMs < now);

  if (expired) return 'free';

  const ids: string[] = Array.isArray(event.entitlement_ids)
    ? (event.entitlement_ids as string[])
    : [];

  let plan = 'free';

  for (const id of ids) {
    const granted = planByEntitlement[id];

    if (granted && planRank.indexOf(granted) > planRank.indexOf(plan)) {
      plan = granted;
    }
  }

  // A plan the seat table does not know would make `inviteMember` fall back
  // to one seat — the safe direction, but silently wrong.
  return plan in seatsByPlan ? plan : 'free';
}

/** Whether the store will bill again. A cancellation clears it, not the plan. */
export function willRenew(event: Record<string, unknown>): boolean {
  return event.cancel_reason == null && event.unsubscribe_detected_at == null;
}
