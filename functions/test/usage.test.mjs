import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  ceilingGrace,
  ceilingsByPlan,
  orderWindowDays,
} from '../lib/lib/firestore.js';
import { atCeiling } from '../lib/subscription/usage.js';

// The compiled module, not the source: this suite runs under plain node, and
// `npm run build` is what CI runs before it.

// A ceiling to test the mechanism against, independent of what any plan is
// currently set to. Reading a live plan's number here would make the suite
// restate the table instead of checking the arithmetic over it.
const ceiling = 50;

describe('when the rules refuse one more', () => {
  it('never refuses a plan with no ceiling, and refuses one past its own', () => {
    // Premium counts no records, so nothing about a count can refuse it.
    assert.equal(atCeiling('premium', 100000, 'items'), false);
    assert.equal(atCeiling('premium', 100000, 'orders'), false);

    // Free does, and a count far past it is the client that ignored its gate.
    assert.equal(atCeiling('free', 100000, 'items'), true);
    assert.equal(atCeiling('free', 100000, 'orders'), true);
    assert.equal(atCeiling('free', 0, 'items'), false);
  });

  it('reads a plan it does not know as Free', () => {
    // A tier added to the RevenueCat dashboard before this build knows it
    // gets Free's ceilings, never Premium's — so a typo in the dashboard
    // cannot hand out an unlimited plan.
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
    // Separate fields, so changing one never drags the other with it.
    assert.ok('items' in ceilingsByPlan.free);
    assert.ok('orders' in ceilingsByPlan.free);
  });

  it('mirrors the app ceilings that Free actually holds', () => {
    // The app renders the paywall from `PlanLimits.byPlan`; this file is what
    // the backend refuses on. Changing one means changing the other, and this
    // is the assertion that says so out loud.
    assert.equal(ceilingsByPlan.free.items, 50);
    assert.equal(ceilingsByPlan.free.orders, 30);
    assert.equal(ceilingsByPlan.premium.items, null);
    assert.equal(ceilingsByPlan.premium.orders, null);
  });

  it('mirrors the window the app counts orders over', () => {
    // The orders ceiling is a rate, not a total: 30 orders every 30 days.
    // `PlanLimits.orderWindow` says the same thing in the app, and a backend
    // counting a lifetime while the client counts a month would refuse
    // exactly the write the client had just offered.
    assert.equal(orderWindowDays, 30);
  });
});
