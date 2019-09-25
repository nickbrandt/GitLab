import _ from 'underscore';
import httpStatus from '~/lib/utils/http_status';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import {
  chartKeys,
  metricTypes,
  columnHighlightStyle,
  defaultMaxColumnChartItemsPerPage,
  maxColumnChartItemsPerPage,
  dataZoomOptions,
  scatterPlotAddonQueryDays,
} from '../../../constants';
import { getScatterPlotData, getMedianLineData } from '../../../utils';

export const chartLoading = state => chartKey => state.charts[chartKey].isLoading;

/**
 * Creates a series object for the column chart with the given chartKey.
 *
 * Takes an object of the form { "1": 10, "2", 20, "3": 30 } (where the key is the x axis value)
 * and transforms it into into the following structure:
 *
 * {
 *   "full": [
 *     { value: ['1', 10], itemStyle: {} },
 *     { value: ['2', 20], itemStyle: {} },
 *     { value: ['3', 30], itemStyle: {} },
 *   ]
 * }
 *
 * The first item in each value array is the x axis value, the second item is the y axis value.
 * If a value is selected (i.e., set on the state's selected array),
 * the itemStyle will be set accordingly in order to highlight the relevant bar.
 *
 */
export const getColumnChartData = state => chartKey => {
  const dataWithSelected = Object.keys(state.charts[chartKey].data).map(key => {
    const dataArr = [key, state.charts[chartKey].data[key]];
    let itemStyle = {};

    if (state.charts[chartKey].selected.indexOf(key) !== -1) {
      itemStyle = columnHighlightStyle;
    }

    return {
      value: dataArr,
      itemStyle,
    };
  });

  return dataWithSelected;
};

export const chartHasData = state => chartKey => !_.isEmpty(state.charts[chartKey].data);
/**
 * Creates a series array of main data for the scatterplot chart.
 *
 * Takes an object of the form
 * {
 *   "1": { "metric": 138", merged_at": "2019-07-09T14:58:07.756Z" },
 *   "2": { "metric": 139, "merged_at": "2019-07-10T11:13:23.557Z" },
 *   "3": { "metric": 24, "merged_at": "2019-07-01T07:06:23.193Z" }
 * }
 *
 * and creates the following structure:
 *
 * [
 *   ["2019-07-01T07:06:23.193Z", 24],
 *   ["2019-07-09T14:58:07.756Z", 138],
 *   ["2019-07-10T11:13:23.557Z", 139],
 * ]
 *
 * It eliminates items which were merged before today minus the selected daysInPast.
 */
export const getScatterPlotMainData = (state, getters, rootState) => {
  const { data } = state.charts.scatterplot;
  const dateInPast = getDateInPast(new Date(), rootState.filters.daysInPast);
  return getScatterPlotData(data, dateInPast);
};

/**
 * Creates a series array of median data for the scatterplot chart.
 *
 * It calls getMedianLineData internally with the raw scatterplot data and the computed by getters.getScatterPlotMainData.
 * scatterPlotAddonQueryDays is necessary since we query the API with an additional day offset to compute the median.
 */
export const getScatterPlotMedianData = (state, getters) =>
  getMedianLineData(
    state.charts.scatterplot.data,
    getters.getScatterPlotMainData,
    scatterPlotAddonQueryDays,
  );

export const getMetricDropdownLabel = state => chartKey =>
  metricTypes.find(m => m.key === state.charts[chartKey].params.metricType).label;

export const getFilterParams = (state, getters, rootState, rootGetters) => chartKey => {
  const { params: chartParams = {} } = state.charts[chartKey];

  // common filter params
  const params = {
    ...rootGetters['filters/getCommonFilterParams'](chartKey),
    chart_type: chartParams.chartType,
  };

  // add additional params depending on chart
  if (chartKey !== chartKeys.main) {
    Object.assign(params, { days_to_merge: state.charts.main.selected });

    if (chartParams) {
      Object.assign(params, { metric_type: chartParams.metricType });
    }
  }

  return params;
};

/**
 * Returns additional options for a given column chart (based on the chartKey)
 * Primarily, it computes the end percentage value for echart's dataZoom property
 *
 * If the number of data items being displayed is below the MAX_ITEMS_PER_PAGE threshold,
 * it will return an empty dataZoom property.
 *
 */
export const getColumnChartDatazoomOption = state => chartKey => {
  const { data } = state.charts[chartKey];
  const totalItems = Object.keys(data).length;
  const MAX_ITEMS_PER_PAGE = maxColumnChartItemsPerPage[chartKey]
    ? maxColumnChartItemsPerPage[chartKey]
    : defaultMaxColumnChartItemsPerPage;

  if (totalItems <= MAX_ITEMS_PER_PAGE) {
    return {};
  }

  const intervalEnd = Math.ceil((MAX_ITEMS_PER_PAGE / totalItems) * 100);

  return {
    dataZoom: dataZoomOptions.map(item => {
      const result = {
        ...item,
        end: intervalEnd,
      };

      return result;
    }),
  };
};

export const getSelectedMetric = state => chartKey => state.charts[chartKey].params.metricType;

export const hasNoAccessError = state =>
  state.charts[chartKeys.main].errorCode === httpStatus.FORBIDDEN;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
