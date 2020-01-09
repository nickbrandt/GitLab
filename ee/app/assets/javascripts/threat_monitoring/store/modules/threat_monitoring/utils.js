import { TIME_WINDOWS, DEFAULT_TIME_WINDOW } from 'ee/threat_monitoring/constants';

export const getTimeWindowConfig = timeWindow =>
  TIME_WINDOWS[timeWindow] || TIME_WINDOWS[DEFAULT_TIME_WINDOW];

/**
 * Get the from/to/interval query parameters for the given time window.
 * @param {string} timeWindow - The time window (keyof TIME_WINDOWS)
 * @param {number} to - Milliseconds past the epoch corresponding to the
 *     returned `to` parameter
 * @returns {Object} Query parameters `from` and `to` are ISO 8601 dates and
 *    `interval` is the configured interval for the time window.
 */
export const getTimeWindowParams = (timeWindow, to) => {
  const { durationInMilliseconds, interval } = getTimeWindowConfig(timeWindow);

  return {
    from: new Date(to - durationInMilliseconds).toISOString(),
    to: new Date(to).toISOString(),
    interval,
  };
};
