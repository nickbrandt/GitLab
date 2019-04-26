import { SORT_FIELDS, SORT_ORDER } from './constants';

export default () => ({
  endpoint: '',
  dependenciesDownloadEndpoint: '',
  initialized: false,
  isLoading: false,
  errorLoading: false,
  dependencies: [],
  pageInfo: {},
  reportStatus: '',
  sortField: 'name',
  sortFields: SORT_FIELDS,
  sortOrder: SORT_ORDER.ascending,
});
