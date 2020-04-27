export default (initialState = {}) => ({
  endpoint: initialState.endpoint,
  loading: false, // TODO - set this to true once integrated with BE
  clusters: [],
  clustersPerPage: 1,
  currentPage: 1,
  totalCount: 0,
  totalPages: 0
});
