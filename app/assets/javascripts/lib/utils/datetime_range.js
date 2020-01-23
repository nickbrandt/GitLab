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

/**
 * convertToFixedRange Transforms a `range of time` into a `fixed range of time`.
 *
 * A a range of time can be understood as an arbitrary period
 * of time that can represent points in time relative to the
 * present moment. Some examples can be:
 *
 * -
 * - From January 1st onwards
 * -
 * - Last 2 days
 * - The next 2 days
 * - Today so far
 *
 * The range of time can take different shapes according to
 * the point of time and type of time range it represents.
 *
 * The following types of ranges can be represented:
 *
 * - Fixed Range: fixed start and ends (e.g. From January 1st 2020 to January 31st 2020)
 * - Anchored Range: a fixed points in time (2 minutes before January 1st, 1 day after )
 * - Rolling Range: a time range relative to now (Last 2 minutes, Next 2 days)
 * - Open Range: a time range relative to now (Before 1st of January, After 1st of January)
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
export const convertToFixedRange = dateTimeRange => {
  if (dateTimeRange.startTime && !dateTimeRange.endTime) {
    // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
    throw new Error('The input fixed range does not have an end time.');
  } else if (!dateTimeRange.startTime && dateTimeRange.endTime) {
    // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
    throw new Error('The input fixed range does not have an end time.');
  } else if (dateTimeRange.startTime && dateTimeRange.endTime) {
    return {
      startTime: new Date(dateTimeRange.startTime).toISOString(),
      endTime: new Date(dateTimeRange.endTime).toISOString(),
    };
  } else if (dateTimeRange.anchor || dateTimeRange.duration) {
    const now = new Date(Date.now());
    const { direction = 'before', duration } = dateTimeRange;
    const anchorDate = dateTimeRange.anchor ? new Date(dateTimeRange.anchor) : now;

    let startDate;
    let endDate;

    if (direction === 'before') {
      startDate = duration ? dateMinusDuration(anchorDate, duration) : MINIMUM_DATE;
      endDate = anchorDate;
    } else {
      startDate = anchorDate;
      endDate = duration ? datePlusDuration(anchorDate, duration) : now;
    }

    return {
      startTime: startDate.toISOString(),
      endTime: endDate.toISOString(),
    };
  }
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  throw new Error('The input range does not have the right format.');
};

export default { convertToFixedRange };
