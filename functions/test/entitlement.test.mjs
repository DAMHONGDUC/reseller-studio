import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { planFromEvent, willRenew } from '../lib/subscription/entitlement.js';

// The compiled module, not the source: `tool/test-rules.sh` runs plain node,
// and `npm run build` is what CI runs before it.

const now = Date.UTC(2026, 7, 23);
const future = now + 30 * 24 * 60 * 60 * 1000;
const past = now - 24 * 60 * 60 * 1000;

describe('which plan a RevenueCat event leaves the seller on', () => {
  it('grants the highest entitlement the event carries', () => {
    const event = { entitlement_ids: ['pro', 'business'], expiration_at_ms: future };

    // A seller who upgraded mid-period holds both for a while, and picking
    // either at random is how Business renders as Pro.
    assert.equal(planFromEvent(event, 'PRODUCT_CHANGE', now), 'business');
  });

  it('keeps the plan through a cancellation, until it actually lapses', () => {
    const cancelled = {
      entitlement_ids: ['pro'],
      expiration_at_ms: future,
      cancel_reason: 'CUSTOMER_SUPPORT',
    };

    // Cancelling is not lapsing. A switch on the event type is how somebody
    // who cancels on the last day of a year loses eleven months they paid for.
    assert.equal(planFromEvent(cancelled, 'CANCELLATION', now), 'pro');
    assert.equal(willRenew(cancelled), false);
  });

  it('drops to free once the period has run out', () => {
    assert.equal(
      planFromEvent({ entitlement_ids: ['pro'], expiration_at_ms: past }, 'RENEWAL', now),
      'free',
    );
    assert.equal(
      planFromEvent({ entitlement_ids: ['pro'], expiration_at_ms: future }, 'EXPIRATION', now),
      'free',
    );
  });

  it('reads an entitlement it does not know as free, never as a neighbour', () => {
    assert.equal(
      planFromEvent(
        { entitlement_ids: ['enterprise'], expiration_at_ms: future },
        'INITIAL_PURCHASE',
        now,
      ),
      'free',
    );
  });

  it('survives an event with nothing in it', () => {
    assert.equal(planFromEvent({}, 'TEST', now), 'free');
    assert.equal(willRenew({}), true);
  });
});
