import { REPORT_STATUS, SORT_FIELDS, SORT_ORDER, DEPENDENCIES_PER_PAGE } from './constants';

export default () => ({
  endpoint: '',
  initialized: false,
  isLoading: false,
  errorLoading: false,
  dependencies: [],
  pageInfo: {
    page: 1,
    perPage: DEPENDENCIES_PER_PAGE,
    total: 0,
  },
  reportInfo: {
    status: REPORT_STATUS.ok,
    jobPath: '',
  },
  sortField: 'name',
  sortFields: SORT_FIELDS,
  sortOrder: SORT_ORDER.ascending,
});
