import { tableSortFields, tableSortOrder } from './../../../constants';

export default () => ({
  isLoadingTable: false,
  hasError: false,
  mergeRequests: [],
  pageInfo: {},
  sortOrder: tableSortOrder.asc.value,
  sortFields: tableSortFields,
  sortField: 'time_to_merge',
  columnMetric: 'time_to_first_comment',
});
