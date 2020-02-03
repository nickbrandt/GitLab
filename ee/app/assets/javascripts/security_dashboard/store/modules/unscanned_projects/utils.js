/* eslint-disable import/prefer-default-export */
import { getDayDifference } from '~/lib/utils/datetime_utility';

/**
 * Checks if a given date instance has been created with a valid date
 *
 * @param date
 * @returns {boolean}
 */
const isValidDate = date => !Number.isNaN(date.getTime());

/**
 * Checks if a given number of days is within a date range
 *
 * @param daysInPast
 * @returns {function({minDays: *, maxDays: *}): boolean|boolean}
 */
const isWithinDateRange = (daysInPast, { fromDay, toDay }) =>
  daysInPast >= fromDay && daysInPast < toDay;

/**
 * Takes an array of objects and groups them based on the given ranges
 *
 * @param ranges
 * @param datePropName
 * @returns {function(*=): *}
 */
export const groupByDateRanges = ({ ranges = [], datePropName = '', projects = [] }) => {
  const dateRangeGroups = projects.reduce((groups, currentProject) => {
    const timeString = currentProject[datePropName];
    const pastDate = new Date(currentProject[datePropName]);

    if (!isValidDate(pastDate) || !timeString) {
      return groups;
    }

    const today = new Date(Date.now());
    const daysInPast = getDayDifference(pastDate, today);

    groups.forEach(group => {
      if (isWithinDateRange(daysInPast, group)) {
        group.projects.push(currentProject);
      }
    });

    return groups;
  }, ranges.map(range => ({ ...range, projects: [] })));

  return dateRangeGroups.filter(group => group.projects.length > 0);
};
