import { tableSortOrder } from '../../../constants';

export default () => ({
  isLoadingTable: false,
  errorCode: null,
  mergeRequests: [],
  pageInfo: {},
  sortOrder: tableSortOrder.asc.value,
  sortField: 'time_to_merge',
  columnMetric: 'time_to_first_comment',
});
