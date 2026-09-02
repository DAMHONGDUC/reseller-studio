import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { fallbackTimeZone, localClock } from '../lib/lib/timezone.js';

// The compiled module, not the source: this suite runs under plain node, and
// `npm run build` is what CI runs before it.

// 08:00 UTC — the instant the digest used to fire for the whole world.
const eightUtc = new Date('2026-03-15T08:00:00Z');

describe('what time it is where the business is', () => {
  it('reads the local hour, not the scheduler’s', () => {
    assert.equal(localClock('Etc/UTC', eightUtc).hour, 8);
    // The bug this exists to fix: 08:00 UTC is 1am in California.
    assert.equal(localClock('America/Los_Angeles', eightUtc).hour, 1);
    assert.equal(localClock('Asia/Ho_Chi_Minh', eightUtc).hour, 15);
  });

  it('follows daylight saving rather than a stored offset', () => {
    // London is UTC in January and UTC+1 in July, on the same field.
    assert.equal(localClock('Europe/London', new Date('2026-01-15T08:00:00Z')).hour, 8);
    assert.equal(localClock('Europe/London', new Date('2026-07-15T08:00:00Z')).hour, 9);
  });

  it('keys the day by the local date, so a dedupe key cannot span two', () => {
    // 23:30 UTC is already the next day in Vietnam.
    const late = new Date('2026-03-15T23:30:00Z');

    assert.equal(localClock('Etc/UTC', late).day, '2026-03-15');
    assert.equal(localClock('Asia/Ho_Chi_Minh', late).day, '2026-03-16');
  });

  it('renders midnight as hour 0, never 24', () => {
    assert.equal(localClock('Etc/UTC', new Date('2026-03-15T00:10:00Z')).hour, 0);
  });

  it('falls back to UTC rather than throwing on a zone nobody knows', () => {
    // One workspace with a typo must not cost every workspace after it its
    // reminders.
    assert.equal(localClock('Mars/Olympus_Mons', eightUtc).hour, 8);
    assert.equal(localClock(undefined, eightUtc).hour, 8);
    assert.equal(localClock('', eightUtc).hour, 8);
    assert.equal(fallbackTimeZone, 'Etc/UTC');
  });
});
