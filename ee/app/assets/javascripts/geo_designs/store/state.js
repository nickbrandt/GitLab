import { FILTER_STATES } from './constants';

const createState = () => ({
  isLoading: false,

  designs: [],
  totalDesigns: 0,
  pageSize: 0,
  currentPage: 1,

  searchFilter: '',
  currentFilterIndex: 0,
  filterOptions: Object.values(FILTER_STATES),
});
export default createState;
