import { secondsToMilliseconds } from './datetime_utility';

const MINIMUM_DATE = new Date(0);

const durationToMillis = duration => {
  if (Object.entries(duration).length === 1 && Number.isFinite(duration.seconds)) {
    return secondsToMilliseconds(duration.seconds);
  }
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  throw new Error('The only duration allowed is Number of `seconds`.');
};

const dateMinusDuration = (date, duration) => new Date(date.getTime() - durationToMillis(duration));

const datePlusDuration = (date, duration) => new Date(date.getTime() + durationToMillis(duration));

function handleRangeDirection({ direction = 'before', anchor, before, after }) {
  let startDate;
  let endDate;

  if (direction === 'before') {
    startDate = before;
    endDate = anchor;
  } else {
    startDate = anchor;
    endDate = after;
  }

  return {
    startDate,
    endDate,
  };
}

/**
 * Converts a fixed range to a fixed range
 * @param {Object} fixedRange - A range with fixed start and end (e.g. From January 1st 2020 to January 31st 2020)
 */
function convertFixedToFixed(fixedRange) {
  //
  return {
    startTime: new Date(fixedRange.startTime).toISOString(),
    endTime: new Date(fixedRange.endTime).toISOString(),
  };
}

/**
 * Converts an anchored range to a fixed range
 * @param {Object} anchoredRange - A duration of time relative to an fixed point in time (2 minutes before January 1st, 1 day after)
 */
function convertAnchoredToFixed(anchoredRange) {
  const anchor = new Date(anchoredRange.anchor);

  const { startDate, endDate } = handleRangeDirection({
    before: dateMinusDuration(anchor, anchoredRange.duration),
    after: datePlusDuration(anchor, anchoredRange.duration),
    direction: anchoredRange.direction,
    anchor,
  });

  return {
    startTime: startDate.toISOString(),
    endTime: endDate.toISOString(),
  };
}

/**
 * Converts a rolling change to a fixed range
 * @param {Object} rollingRange - a time range relative to now (Last 2 minutes, Next 2 days)
 */
function convertRollingToFixed(rollingRange) {
  const now = new Date(Date.now());

  return convertAnchoredToFixed({
    duration: rollingRange.duration,
    direction: rollingRange.direction,
    anchor: now.toISOString(),
  });
}

/**
 * Converts an open range to a fixed range
 * @param {Object} openRange - a time range relative to an anchor (Before 1st of January, After 1st of January)
 */
function convertOpenToFixed(openRange) {
  const now = new Date(Date.now());
  const anchor = new Date(openRange.anchor);

  const { startDate, endDate } = handleRangeDirection({
    before: MINIMUM_DATE,
    after: now,
    direction: openRange.direction,
    anchor,
  });

  return {
    startTime: startDate.toISOString(),
    endTime: endDate.toISOString(),
  };
}

function handleInvalidRange(range) {
  const hasStart = range.startTime;
  const hasEnd = range.endTime;

  /* eslint-disable @gitlab/i18n/no-non-i18n-strings */
  const messages = {
    [true]: 'The input range does not have the right format.',
    [!hasStart && hasEnd]: 'The input fixed range does not have a start time.',
    [hasStart && !hasEnd]: 'The input fixed range does not have an end time.',
  };
  /* eslint-enable @gitlab/i18n/no-non-i18n-strings */

  throw new Error(messages.true);
}

const handlers = {
  invalid: handleInvalidRange,
  fixed: convertFixedToFixed,
  anchored: convertAnchoredToFixed,
  rolling: convertRollingToFixed,
  open: convertOpenToFixed,
};

export function getRangeType(range) {
  const hasStart = range.startTime;
  const hasEnd = range.endTime;
  const hasAnchor = range.anchor;
  const hasDuration = range.duration;

  const types = {
    fixed: hasStart && hasEnd,
    anchored: hasAnchor && hasDuration,
    rolling: hasDuration && !hasAnchor,
    open: hasAnchor && !hasDuration,
  };

  return (Object.entries(types).find(([, truthy]) => truthy) || ['invalid'])[0];
}

/**
 * convertToFixedRange Transforms a `range of time` into a `fixed range of time`.
 *
 * A a range of time can be understood as an arbitrary period
 * of time that can represent points in time relative to the
 * present moment:
 *
 * The range of time can take different shapes according to
 * the point of time and type of time range it represents.
 *
 * The following types of ranges can be represented:
 *
 * Fixed Range: A range with fixed start and end (e.g. From January 1st 2020 to January 31st 2020)
 * Anchored Range: A duration of time relative to an fixed point in time (2 minutes before January 1st, 1 day after)
 * Rolling Range: A time range relative to now (Last 2 minutes, Next 2 days)
 * Open Range: A time range relative to an anchor (Before 1st of January, After 1st of January)
 *
 * @param {Object} dateTimeRange - A Time Range representation
 * It contains the data needed to create a fixed time range plus
 * a label (recommended) to indicate the range that is covered.
 *
 * A definition via a TypeScript notation is presented below:
 *
 *
 * type Duration = { // A duration of time, always in seconds
 *   seconds: number;
 * }
 *
 * type Direction = 'before' | 'after'; // Direction of time
 *
 * type FixedRange = {
 *   start: ISO8601;
 *   end: ISO8601;
 *   label: string;
 * }
 *
 * type AnchoredRange = {
 *   anchor: ISO8601;
 *   duration: Duration;
 *   direction: Direction;
 *   label: string;
 * }
 *
 * type RollingRange = {
 *   duration: Duration;
 *   direction: Direction;
 *   label: string;
 * }
 *
 * type OpenRange = {
 *   anchor: ISO8601;
 *   direction: Direction;
 *   label: string;
 * }
 *
 * type DateTimeRange = FixedRange | AnchoredRange | RollingRange | OpenRange;
 *
 *
 * @returns An object with a fixed startTime and endTime that
 * corresponds to the input time.
 */
export const convertToFixedRange = dateTimeRange =>
  handlers[getRangeType(dateTimeRange)](dateTimeRange);
