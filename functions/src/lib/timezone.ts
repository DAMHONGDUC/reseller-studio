/**
 * What time it is where a business is, rather than where the scheduler runs.
 *
 * **A workspace stores an IANA `timezone`** (`docs/DATA_MODEL.md`) and nothing
 * was reading it: the digest fired at 08:00 UTC for everybody, which is 1am in
 * California. A reminder that arrives in the middle of the night is one the
 * seller turns off, and it takes the notifications that matter with it.
 *
 * `Intl` rather than stored offsets, because an offset is wrong twice a year
 * and a stored one would be wrong until somebody noticed.
 */

/** Used when a workspace names no timezone, or names one ICU does not know. */
export const fallbackTimeZone = 'Etc/UTC';

export interface LocalClock {
  /** Hour of the local day, 0–23. */
  hour: number;

  /** The local calendar date as `YYYY-MM-DD` — a dedupe key, not a display. */
  day: string;
}

/**
 * [at] as the wall clock reads in [timeZone].
 *
 * **An unknown zone falls back to UTC rather than throwing.** One workspace
 * with a typo in its settings must not cost every workspace after it its
 * reminders.
 */
export function localClock(timeZone: string | undefined, at: Date = new Date()): LocalClock {
  const zone = timeZone && timeZone.length > 0 ? timeZone : fallbackTimeZone;

  try {
    return read(zone, at);
  } catch {
    return read(fallbackTimeZone, at);
  }
}

function read(timeZone: string, at: Date): LocalClock {
  // `hourCycle: 'h23'` because `hour12: false` renders midnight as 24 in some
  // ICU builds, which would make an hour comparison silently miss a day.
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(at);

  const value = (type: Intl.DateTimeFormatPartTypes): string =>
    parts.find((part) => part.type === type)?.value ?? '';

  return {
    hour: Number(value('hour')),
    day: `${value('year')}-${value('month')}-${value('day')}`,
  };
}
