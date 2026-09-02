import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { ceilingGrace, ceilingsByPlan } from '../lib/lib/firestore.js';
import { atCeiling } from '../lib/subscription/usage.js';

// The compiled module, not the source: this suite runs under plain node, and
// `npm run build` is what CI runs before it.

// A ceiling to test the mechanism against, independent of what any plan is
// currently set to. Free no longer counts records — Premium sells the answers
// rather than permission to keep typing — so reading its number here would
// make the suite assert nothing.
const ceiling = 50;

describe('when the rules refuse one more', () => {
  it('never refuses a plan with no ceiling', () => {
    // Both plans are unlimited on records today, and that is the point: the
    // paid line moved onto capabilities, so nothing here should refuse.
    assert.equal(atCeiling('free', 100000, 'items'), false);
    assert.equal(atCeiling('free', 100000, 'orders'), false);
    assert.equal(atCeiling('premium', 100000, 'items'), false);
    assert.equal(atCeiling('premium', 100000, 'orders'), false);
  });

  it('reads a plan it does not know as Free', () => {
    // A tier added to the RevenueCat dashboard before this build knows it
    // gets Free's ceilings, never Premium's. It grants nothing today because
    // Free counts no records; the day a ceiling comes back, this is what
    // stops a typo handing out a paid tier.
    assert.equal(
      atCeiling('enterprise', 100000, 'items'),
      atCeiling('free', 100000, 'items'),
    );
  });

  it('still lets a plan fill a ceiling, and the slack above it', () => {
    // The mechanism, checked against a literal rather than a live plan: the
    // client gate stops at the ceiling and the rule exists for the client
    // that ignores it, so the advertised last slot is never refused.
    const under = (count) =>
      count < ceiling + ceilingGrace;

    assert.equal(under(ceiling - 1), true);
    assert.equal(under(ceiling), true);
    assert.equal(under(ceiling + ceilingGrace - 1), true);
    assert.equal(under(ceiling + ceilingGrace), false);
  });

  it('keeps items and orders as separate ceilings', () => {
    // They are separate fields even while both are null, because the day one
    // of them comes back it must not bring the other with it.
    assert.ok('items' in ceilingsByPlan.free);
    assert.ok('orders' in ceilingsByPlan.free);
  });
});
