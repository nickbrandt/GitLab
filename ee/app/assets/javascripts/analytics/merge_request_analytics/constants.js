import { __ } from '~/locale';

export const DEFAULT_NUMBER_OF_DAYS = 365;
export const THROUGHPUT_CHART_STRINGS = {
  CHART_TITLE: __('Throughput'),
  Y_AXIS_TITLE: __('Merge Requests merged'),
  X_AXIS_TITLE: __('Month'),
  CHART_DESCRIPTION: __('The number of merge requests merged by month.'),
  NO_DATA: __('There is no chart data available.'),
  ERROR_FETCHING_DATA: __('There was an error while fetching the chart data.'),
};
