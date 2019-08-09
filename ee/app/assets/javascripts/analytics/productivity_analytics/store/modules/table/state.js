import { __ } from '~/locale';
import { chartKeys, tableSortOrder, metricTypes } from './../../../constants';

const sortFields = metricTypes.reduce(
  (acc, curr) => {
    const { key, label, chart } = curr;
    if (chart === chartKeys.timeBasedHistogram) {
      acc[key] = label;
    }
    return acc;
  },
  { days_to_merge: __('Days to merge') },
);

export default () => ({
  isLoadingTable: false,
  hasError: false,
  mergeRequests: [],
  pageInfo: {},
  sortOrder: tableSortOrder.asc.value,
  sortFields,
  sortField: 'time_to_merge',
  columnMetric: 'time_to_first_comment',
});
