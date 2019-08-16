import { chartKeys, chartTypes } from '../../../constants';

export default () => ({
  charts: {
    [chartKeys.main]: {
      isLoading: false,
      hasError: false,
      data: {},
      selected: [],
      params: {
        chartType: chartTypes.histogram,
      },
    },
    [chartKeys.timeBasedHistogram]: {
      isLoading: false,
      hasError: false,
      data: {},
      selected: [],
      params: {
        metricType: 'time_to_first_comment',
        chartType: chartTypes.histogram,
      },
    },
    [chartKeys.commitBasedHistogram]: {
      isLoading: false,
      hasError: false,
      data: {},
      selected: [],
      params: {
        metricType: 'commits_count',
        chartType: chartTypes.histogram,
      },
    },
    [chartKeys.scatterplot]: {
      isLoading: false,
      hasError: false,
      data: {},
      selected: [],
      params: {
        chartType: chartTypes.scatterplot,
      },
    },
  },
});
