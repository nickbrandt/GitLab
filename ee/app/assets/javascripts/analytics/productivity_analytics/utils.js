import { getDayDifference, getDateInPast } from '~/lib/utils/datetime_utility';
import { median } from '~/lib/utils/number_utils';

/**
 * Gets the labels endpoint for a given group or project
 * @param {String} namespacePath - The group's namespace.
 * @param {String} projectPathWithNamespace - The project's name including the group's namespace
 * @returns {String} - The labels endpoint path
 */
export const getLabelsEndpoint = (namespacePath, projectPathWithNamespace) => {
  if (projectPathWithNamespace) {
    return `/${projectPathWithNamespace}/-/labels`;
  }

  return `/groups/${namespacePath}/-/labels`;
};

/**
 * Gets the milestones endpoint for a given group or project
 * @param {String} namespacePath - The group's namespace.
 * @param {String} projectPathWithNamespace - The project's name including the group's namespace
 * @returns {String} - The milestones endpoint path
 */
export const getMilestonesEndpoint = (namespacePath, projectPathWithNamespace) => {
  if (projectPathWithNamespace) {
    return `/${projectPathWithNamespace}/-/milestones`;
  }

  return `/groups/${namespacePath}/-/milestones`;
};

/**
 * Computes the day difference 'days' between a given start and end date
 * and creates an array of length 'days'.
 * For each day in the array it initializes an empty array.
 *
 * E.g. initDateArray(new Date('2019-01-01'), new Date('2019-01-03'))
 * the following data structure gets generated: [ [], [], [] ]
 * @param {Date} startDate - The start date
 * @param {Date} endDate - The end date
 */
export const initDateArray = (startDate, endDate) => {
  const days = getDayDifference(startDate, endDate);
  return Array.from({ length: days + 1 }, () => []);
};

/**
 * Transforms the raw scatter data into a data strucuture that allows easy access.
 * It creates a two dimensional array where each item in the first dimension corresponds to one day (date).
 *
 * I.e., the first item corresponds to the start date, the second item corresponds to the start date plus one day,
 * the last item corresponds to the end date.
 *
 * For each date, we store an array of individual MRs for the particular date (i.e, the second dimension) in the following form:
 * { merged_at: '2019-09-01T04:55:05.757Z', metric: 10 }
 *
 * Given that startDate=2019-09-01 and endDate=2019-09-03 we receive the following data structure:
 * [
 *   [{ merged_at: '2019-09-01T04:55:05.757Z', metric: 10 }, { merged_at: '2019-09-01T14:12:09.757Z', metric: 8 }, { ... }] // 2019-09-01
 *   [{ merged_at: '2019-09-02T08:29:33.748Z', metric: 7 }, ... ] // 2019-09-02
 *   [{ merged_at: '2019-09-03T21:29:49.351Z', metric: 24 }, ... ] // 2019-09-03
 * ]
 *
 * @param {*} data - The raw data received from the API.
 * @param {*} startDate - The start date selected by the user minus an additional offset in days (e.g., 30 days).
 * @param {*} endDate - The end date selected by the user.
 * @returns {Array} The transformed data array (first item corresponds to start date, last item to end date)
 */
export const transformScatterData = (data, startDate, endDate) => {
  const result = initDateArray(startDate, endDate);
  const totalItems = result.length;

  Object.keys(data).forEach(id => {
    const mergedAtDate = new Date(data[id].merged_at);
    const d = new Date();
    d.setDate(mergedAtDate.getDate());
    d.setMonth(mergedAtDate.getMonth());
    d.setFullYear(mergedAtDate.getFullYear());

    const dayDiff = getDayDifference(d, endDate);
    if (dayDiff > -1) {
      const idx = totalItems - (dayDiff + 1);
      result[idx].push(data[id]);
    }
  });

  return result;
};

/**
 * Transforms a given data object into an array
 * which will be used as series data for the scatterplot chart.
 * It eliminates items which were merged before a "dateInPast" and sorts
 * the result by date (ascending)
 *
 * Takes an object of the form
 * {
 *   "1": { "metric": 138", merged_at": "2019-07-09T14:58:07.756Z" },
 *   "2": { "metric": 139, "merged_at": "2019-07-10T11:13:23.557Z" },
 *   "3": { "metric": 24, "merged_at": "2019-07-01T07:06:23.193Z" }
 * }
 *
 * and creates the following two-dimensional array
 * where the first value is the "merged_at" date and the second value is the metric:
 *
 * [
 *   ["2019-07-01T07:06:23.193Z", 24],
 *   ["2019-07-09T14:58:07.756Z", 138],
 *   ["2019-07-10T11:13:23.557Z", 139],
 * ]
 *
 * @param {Object} data The raw data which will be transformed
 * @param {Date} dateInPast Date in the past
 * @returns {Array} The transformed data array sorted by date ascending
 */
export const getScatterPlotData = (data, dateInPast) =>
  Object.keys(data)
    .filter(key => new Date(data[key].merged_at) >= dateInPast)
    .map(key => [data[key].merged_at, data[key].metric])
    .sort((a, b) => new Date(a[0]) - new Date(b[0]));

/**
 * Computes the moving median line data.
 * It takes the raw data object (which contains historical data) and the scatterData (from getScatterPlotData)
 * and computes the median for every date in scatterData.
 * The median for a given date in scatterData (called item) is computed by taking all metrics of the raw data into account
 * which are before (or eqaul to) the the item's merged_at date
 * and after (or equal to) the item's merged_at date minus a given "daysOffset" (e.g., 30 days for "30 day rolling median")
 *
 * i.e., moving median for a given DAY is the median the range of values (DAY-30 ... DAY)
 *
 * @param {Object} data The raw data which will be used for computing the median
 * @param {Array} scatterData The transformed data from getScatterPlotData
 * @param {Number} daysOffset The number of days that is substracted from each date in scatterData (e.g. 30 days in the past)
 * @returns {Array} An array with each item being another arry of two items (date, computed median)
 */
export const getMedianLineData = (data, scatterData, daysOffset) =>
  scatterData.map(item => {
    const [dateString] = item;
    const values = Object.keys(data)
      .filter(key => {
        const mergedAtDate = new Date(data[key].merged_at);
        const itemDate = new Date(dateString);

        return (
          mergedAtDate <= itemDate && mergedAtDate >= new Date(getDateInPast(itemDate, daysOffset))
        );
      })
      .map(key => data[key].metric);

    const computedMedian = values.length ? median(values) : 0;
    return [dateString, computedMedian];
  });
