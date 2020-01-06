import { isString, isNumber } from 'underscore';
import dateFormat from 'dateformat';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { newDate, dayAfter, secondsToDays, getDatesInRange } from '~/lib/utils/datetime_utility';
import { dateFormats } from '../shared/constants';
import { STAGE_NAME } from './constants';
import { toYmd } from '../shared/utils';

const EVENT_TYPE_LABEL = 'label';

export const isStartEvent = ev => Boolean(ev) && Boolean(ev.canBeStartEvent) && ev.canBeStartEvent;

export const eventToOption = (obj = null) => {
  if (!obj || (!obj.text && !obj.identifier)) return null;
  const { name: text = '', identifier: value = null } = obj;
  return { text, value };
};

export const getAllowedEndEvents = (events = [], targetIdentifier = null) => {
  if (!targetIdentifier || !events.length) return [];
  const st = events.find(({ identifier }) => identifier === targetIdentifier);
  return st && st.allowedEndEvents ? st.allowedEndEvents : [];
};

export const eventsByIdentifier = (events = [], targetIdentifier = []) => {
  if (!targetIdentifier || !targetIdentifier.length || !events.length) return [];
  return events.filter(({ identifier = '' }) => targetIdentifier.includes(identifier));
};

export const isLabelEvent = (labelEvents = [], ev = null) =>
  Boolean(ev) && labelEvents.length && labelEvents.includes(ev);

export const getLabelEventsIdentifiers = (events = []) =>
  events.filter(ev => ev.type && ev.type === EVENT_TYPE_LABEL).map(i => i.identifier);

/**
 * Checks if the specified stage is in memory or persisted to storage based on the id
 *
 * Default cycle analytics stages are initially stored in memory, when they are first
 * created the id for the stage is the name of the stage in lowercase. This string id
 * is used to fetch stage data (events, median calculation)
 *
 * When either a custom stage is created or an edit is made to a default stage then the
 * default stages get persisted to storage and will have a numeric id. The new numeric
 * id should then be used to access stage data
 *
 */
export const isPersistedStage = ({ custom, id }) => custom || isNumber(id);

/**
 * Returns the the correct slug to use for a stage
 * default stages use the snakecased title of the stage, while custom
 * stages will have a numeric id
 *
 * @param {Object} obj
 * @param {string} obj.title - title of the stage
 * @param {number} obj.id - numerical object id available for custom stages
 * @param {boolean} obj.custom - boolean flag indicating a custom stage
 * @returns {(number|string)} Returns a numerical id for customs stages and string for default stages
 */
const stageUrlSlug = ({ id, title, custom = false }) => {
  if (custom) return id;
  // We still use 'production' as the id to access this stage, even though the title is 'Total'
  return title.toLowerCase() === STAGE_NAME.TOTAL
    ? STAGE_NAME.PRODUCTION
    : convertToSnakeCase(title);
};

export const transformRawStages = (stages = []) =>
  stages.map(({ id, title, name = '', custom = false, ...rest }) => ({
    ...convertObjectPropsToCamelCase(rest, { deep: true }),
    id,
    title,
    custom,
    slug: isPersistedStage({ custom, id }) ? id : stageUrlSlug({ custom, id, title }),
    // the name field is used to create a stage, but the get request returns title
    name: name.length ? name : title,
  }));

export const arrayToObject = (arr = []) =>
  arr.reduce((acc, curr) => {
    const [key, value] = curr;
    return { ...acc, [key]: value };
  }, {});

// converts the series data into key value pairs
export const transformRawTasksByTypeData = (data = []) => {
  // TODO: does processing here make sense? if so add specs
  if (!data.length) return [];
  return data.map(({ series, ...rest }) =>
    convertObjectPropsToCamelCase(
      {
        ...rest,
        series: arrayToObject(series),
      },
      { deep: true },
    ),
  );
};

export const nestQueryStringKeys = (obj = null, targetKey = '') => {
  if (!obj || !isString(targetKey) || !targetKey.length) return {};
  return Object.entries(obj).reduce((prev, [key, value]) => {
    const customKey = `${targetKey}[${key}]`;
    return { ...prev, [customKey]: value };
  }, {});
};

/**
 * Takes the duration data for selected stages, transforms the date values and returns
 * the data in a flattened array
 *
 * The received data is expected to be the following format; One top level object in the array per stage,
 * each potentially having multiple data entries.
 * [
 *   {
 *    slug: 'issue',
 *    selected: true,
 *    data: [
 *      {
 *        'duration_in_seconds': 1234,
 *        'finished_at': '2019-09-02T18:25:43.511Z'
 *      },
 *      ...
 *    ]
 *   },
 *   ...
 * ]
 *
 * The data is then transformed and flattened into the following format;
 * [
 *  {
 *    'duration_in_seconds': 1234,
 *    'finished_at': '2019-09-02'
 *  },
 *  ...
 * ]
 *
 * @param {Array} data - The duration data for selected stages
 * @returns {Array} An array with each item being an object containing the duration_in_seconds and finished_at values for an event
 */
export const flattenDurationChartData = data =>
  data
    .map(stage =>
      stage.data.map(event => {
        const date = new Date(event.finished_at);
        return {
          ...event,
          finished_at: dateFormat(date, dateFormats.isoDate),
        };
      }),
    )
    .flat();

/**
 * Takes the duration data for selected stages, groups the data by day and calculates the total duration
 * per day.
 *
 * The received data is expected to be the following format; One top level object in the array per stage,
 * each potentially having multiple data entries.
 * [
 *   {
 *    slug: 'issue',
 *    selected: true,
 *    data: [
 *      {
 *        'duration_in_seconds': 1234,
 *        'finished_at': '2019-09-02T18:25:43.511Z'
 *      },
 *      ...
 *    ]
 *   },
 *   ...
 * ]
 *
 * The data is then computed and transformed into a format that can be passed to the chart:
 * [
 *  ['2019-09-02', 7, '2019-09-02'],
 *  ['2019-09-03', 10, '2019-09-03'],
 *  ['2019-09-04', 8, '2019-09-04'],
 *  ...
 * ]
 *
 * In the data above, each array i represents a point in the scatterplot with the following data:
 * i[0] = date, displayed on x axis
 * i[1] = metric, displayed on y axis
 * i[2] = date, used in the tooltip
 *
 * @param {Array} data - The duration data for selected stages
 * @param {Date} startDate - The globally selected cycle analytics start date
 * @param {Date} endDate - The globally selected cycle analytics stendart date
 * @returns {Array} An array with each item being another arry of three items (plottable date, computed total, tooltip display date)
 */
export const getDurationChartData = (data, startDate, endDate) => {
  const flattenedData = flattenDurationChartData(data);
  const eventData = [];

  for (
    let currentDate = newDate(startDate);
    currentDate <= endDate;
    currentDate = dayAfter(currentDate)
  ) {
    const currentISODate = dateFormat(newDate(currentDate), dateFormats.isoDate);
    const valuesForDay = flattenedData.filter(object => object.finished_at === currentISODate);
    const summedData = valuesForDay.reduce((total, value) => total + value.duration_in_seconds, 0);
    const summedDataInDays = secondsToDays(summedData);

    if (summedDataInDays) eventData.push([currentISODate, summedDataInDays, currentISODate]);
  }

  return eventData;
};

const toUnix = datetime => new Date(datetime).getTime();
export const orderByDate = (a, b) => toUnix(a) - toUnix(b);

// TODO: code blocks + specs
// The api only returns datapoints with a value, 0 values are ignored
const zeroMissingDataPoints = ({ data, defaultData }) => {
  // overwrites the default values with any value that was returned from the api
  return { ...defaultData, ...data };
};

// TODO: docblocks
// Array of values [date, value]
// ignore the date, just return the value, default sort by ascending date
export const flattenTaskByTypeSeries = (series = {}) =>
  Object.entries(series)
    .sort((a, b) => orderByDate(a[0], b[0]))
    .map(dataSet => dataSet[1]);

// TODO: docblocks
// GROSS
export const getTasksByTypeData = ({ data = [], startDate = null, endDate = null }) => {
  // TODO: check that the date range and datapoint values are in the same order
  if (!startDate || !endDate || !data.length) {
    return {
      range: [],
      seriesData: [],
      seriesNames: [],
    };
  }

  const range = getDatesInRange(startDate, endDate, toYmd).sort(orderByDate);
  const defaultData = range.reduce(
    (acc, date) => ({
      ...acc,
      [date]: 0,
    }),
    {},
  );
  // TODO: handle zero's?
  // TODO: fixup seeded data so it falls in the correct date range

  const transformed = data.reduce(
    (acc, curr) => {
      const {
        label: { title },
        series,
      } = curr;
      // TODO: double check if BE fills in all the dates and adds zeros
      acc.seriesNames = [...acc.seriesNames, title];
      // TODO: maybe flatmap
      // series is already an object at this point
      const fullData = zeroMissingDataPoints({ data: series, defaultData });
      acc.seriesData = [...acc.seriesData, flattenTaskByTypeSeries(fullData)];
      return acc;
    },
    {
      seriesData: [],
      seriesNames: [],
    },
  );

  return {
    ...transformed,
    range,
  };
};
