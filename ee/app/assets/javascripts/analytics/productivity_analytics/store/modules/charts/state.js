import { chartKeys, chartTypes } from '../../../constants';

export default () => ({
  charts: {
    [chartKeys.main]: {
      isLoading: false,
      errorCode: null,
      enabled: true,
      data: {},
      selected: [],
      params: {
        chartType: chartTypes.histogram,
      },
    },
    [chartKeys.timeBasedHistogram]: {
      isLoading: false,
      errorCode: null,
      enabled: true,
      data: {},
      selected: [],
      params: {
        metricType: 'time_to_first_comment',
        chartType: chartTypes.histogram,
      },
    },
    [chartKeys.commitBasedHistogram]: {
      isLoading: false,
      errorCode: null,
      enabled: true,
      data: {},
      selected: [],
      params: {
        metricType: 'commits_count',
        chartType: chartTypes.histogram,
      },
    },
    [chartKeys.scatterplot]: {
      isLoading: false,
      errorCode: null,
      enabled: true,
      data: {},
      transformedData: [],
      selected: [],
      params: {
        chartType: chartTypes.scatterplot,
        metricType: 'days_to_merge',
      },
    },
  },
});
