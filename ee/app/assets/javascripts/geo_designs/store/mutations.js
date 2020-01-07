import * as types from './mutation_types';

export default {
  [types.SET_FILTER](state, filterIndex) {
    state.currentPage = 1;
    state.currentFilterIndex = filterIndex;
  },
  [types.SET_SEARCH](state, search) {
    state.currentPage = 1;
    state.searchFilter = search;
  },
  [types.SET_PAGE](state, page) {
    state.currentPage = page;
  },
  [types.REQUEST_DESIGNS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_DESIGNS_SUCCESS](state, { data, perPage, total }) {
    state.isLoading = false;
    state.designs = data;
    state.pageSize = perPage;
    state.totalDesigns = total;
  },
  [types.RECEIVE_DESIGNS_ERROR](state) {
    state.isLoading = false;
    state.designs = [];
    state.pageSize = 0;
    state.totalDesigns = 0;
  },
  [types.REQUEST_INITIATE_ALL_DESIGN_SYNCS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_INITIATE_ALL_DESIGN_SYNCS_SUCCESS](state) {
    state.isLoading = false;
  },
  [types.RECEIVE_INITIATE_ALL_DESIGN_SYNCS_ERROR](state) {
    state.isLoading = false;
  },
  [types.REQUEST_INITIATE_DESIGN_SYNC](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_INITIATE_DESIGN_SYNC_SUCCESS](state) {
    state.isLoading = false;
  },
  [types.RECEIVE_INITIATE_DESIGN_SYNC_ERROR](state) {
    state.isLoading = false;
  },
};
