import { REPORT_STATUS, SORT_ORDER } from './constants';

export default () => ({
  endpoint: '',
  initialized: false,
  isLoading: false,
  errorLoading: false,
  dependencies: [],
  pageInfo: {},
  reportInfo: {
    status: REPORT_STATUS.ok,
    jobPath: '',
  },
  sortField: 'name',
  sortOrder: SORT_ORDER.ascending,
});
