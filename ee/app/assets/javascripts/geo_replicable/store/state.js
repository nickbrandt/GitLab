import { FILTER_STATES } from '../constants';

const createState = ({ replicableType, useGraphQl }) => ({
  replicableType,
  useGraphQl,
  isLoading: false,

  replicableItems: [],
  paginationData: {
    // GraphQL
    hasNextPage: false,
    hasPreviousPage: false,
    startCursor: '',
    endCursor: '',
    // RESTful
    total: 0,
    perPage: 0,
    page: 1,
  },

  searchFilter: '',
  currentFilterIndex: 0,
  filterOptions: Object.values(FILTER_STATES),
});
export default createState;
