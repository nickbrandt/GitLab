import { __, s__ } from '~/locale';

export const chartKeys = {
  main: 'main',
  timeBasedHistogram: 'timeBasedHistogram',
  commitBasedHistogram: 'commitBasedHistogram',
  scatterplot: 'scatterplot',
};

export const chartTypes = {
  histogram: 'histogram',
  scatterplot: 'scatterplot',
};

export const metricTypes = [
  {
    key: 'time_to_first_comment',
    label: __('Time from first commit until first comment'),
    chart: chartKeys.timeBasedHistogram,
  },
  {
    key: 'time_to_last_commit',
    label: __('Time from first comment to last commit'),
    chart: chartKeys.timeBasedHistogram,
  },
  {
    key: 'time_to_merge',
    label: __('Time from last commit to merge'),
    chart: chartKeys.timeBasedHistogram,
  },
  {
    key: 'commits_count',
    label: __('Number of commits per MR'),
    chart: chartKeys.commitBasedHistogram,
  },
  {
    key: 'loc_per_commit',
    label: __('Number of LOCs per commit'),
    chart: chartKeys.commitBasedHistogram,
  },
  {
    key: 'files_touched',
    label: __('Number of files touched'),
    chart: chartKeys.commitBasedHistogram,
  },
];

export const tableSortFields = metricTypes.reduce(
  (acc, curr) => {
    const { key, label, chart } = curr;
    if (chart === chartKeys.timeBasedHistogram) {
      acc[key] = label;
    }
    return acc;
  },
  { days_to_merge: __('Days to merge') },
);

export const tableSortOrder = {
  asc: {
    title: s__('ProductivityAnalytics|Ascending'),
    value: 'asc',
    icon: 'sort-lowest',
  },
  desc: {
    title: s__('ProductivityAnalytics|Descending'),
    value: 'desc',
    icon: 'sort-highest',
  },
};

export const timeToMergeMetric = 'time_to_merge';

export const defaultMaxColumnChartItemsPerPage = 20;

export const maxColumnChartItemsPerPage = {
  [chartKeys.main]: 40,
};

export const dataZoomOptions = [
  {
    type: 'slider',
    bottom: 10,
    start: 0,
  },
  {
    type: 'inside',
    start: 0,
  },
];

/**
 * #418cd8 --> $blue-400 (see variables.scss)
 */
export const columnHighlightStyle = { color: '#418cd8', opacity: 0.8 };

export const accessLevelReporter = 20;
