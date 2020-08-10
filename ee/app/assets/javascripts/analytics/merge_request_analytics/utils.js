import { getMonthNames, dateFromParams } from '~/lib/utils/datetime_utility';
import dateFormat from 'dateformat';

/**
 * A utility function which accepts a date range and returns
 * computed month data which is required to build the GraphQL
 * query for the Throughput Analytics chart
 *
 * This does not currently support days;
 *
 * `mergedAfter` will always be the first day of the month
 * `mergedBefore` will always be the first day of the following month
 *
 * @param {Date} startDate the startDate for the data range
 * @param {Date} endDate the endDate for the data range
 * @param {String} format the date format to be used
 *
 * @return {Array} the computed month data
 */
// eslint-disable-next-line import/prefer-default-export
export const computeMonthRangeData = (startDate, endDate, format = 'yyyy-mm-dd') => {
  const monthData = [];
  const monthNames = getMonthNames(true);

  for (
    let dateCursor = endDate;
    dateCursor >= startDate;
    dateCursor.setMonth(dateCursor.getMonth() - 1)
  ) {
    const monthIndex = dateCursor.getMonth();
    const year = dateCursor.getFullYear();

    const mergedAfter = dateFromParams(year, monthIndex, 1);
    const mergedBefore = dateFromParams(year, monthIndex + 1, 1);

    monthData.unshift({
      year,
      month: monthNames[monthIndex],
      mergedAfter: dateFormat(mergedAfter, format),
      mergedBefore: dateFormat(mergedBefore, format),
    });
  }

  return monthData;
};
