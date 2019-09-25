import { getDateInPast } from '~/lib/utils/datetime_utility';
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
 * @param {String} dateInPast Date string in ISO format
 * @returns {Array} The transformed data array sorted by date ascending
 */
export const getScatterPlotData = (data, dateInPast) =>
  Object.keys(data)
    .filter(key => new Date(data[key].merged_at) >= new Date(dateInPast))
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
