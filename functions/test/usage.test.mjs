import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { ceilingGrace, ceilingsByPlan } from '../lib/lib/firestore.js';
import { atCeiling } from '../lib/subscription/usage.js';

// The compiled module, not the source: this suite runs under plain node, and
// `npm run build` is what CI runs before it.

const free = ceilingsByPlan.free.items;

describe('when the rules refuse one more', () => {
  it('lets a Free workspace fill its ceiling, and the slack above it', () => {
    // The client gate stops at the ceiling; the rule exists for the client
    // that ignores it, so the advertised last slot must never be refused.
    assert.equal(atCeiling('free', free - 1, 'items'), false);
    assert.equal(atCeiling('free', free, 'items'), false);
    assert.equal(atCeiling('free', free + ceilingGrace - 1, 'items'), false);
  });

  it('refuses once the count is past the ceiling and the slack', () => {
    assert.equal(atCeiling('free', free + ceilingGrace, 'items'), true);
    assert.equal(atCeiling('free', free + 500, 'items'), true);
  });

  it('never refuses a plan with no ceiling', () => {
    assert.equal(atCeiling('premium', 100000, 'items'), false);
    assert.equal(atCeiling('premium', 100000, 'orders'), false);
  });

  it('reads a plan it does not know as Free', () => {
    // A tier added to the RevenueCat dashboard before this build knows it
    // must not come out unlimited — that is a paid tier granted by a typo.
    assert.equal(atCeiling('enterprise', free + ceilingGrace, 'items'), true);
  });

  it('counts items and orders against their own ceilings', () => {
    const orders = ceilingsByPlan.free.orders;

    assert.equal(atCeiling('free', orders + ceilingGrace, 'orders'), true);
    assert.equal(atCeiling('free', orders + ceilingGrace, 'items'), false);
  });
});
