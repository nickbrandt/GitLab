import * as types from './mutation_types';
import { SORT_ORDER } from './constants';

export default {
  [types.SET_DEPENDENCIES_ENDPOINT](state, payload) {
    state.endpoint = payload;
  },
  [types.SET_DEPENDENCIES_DOWNLOAD_ENDPOINT](state, payload) {
    state.dependenciesDownloadEndpoint = payload;
  },
  [types.REQUEST_DEPENDENCIES](state) {
    state.isLoading = true;
    state.errorLoading = false;
  },
  [types.RECEIVE_DEPENDENCIES_SUCCESS](state, { dependencies, pageInfo }) {
    state.dependencies = dependencies;
    state.pageInfo = pageInfo;
    state.isLoading = false;
    state.errorLoading = false;
    state.reportStatus = '';
    state.initialized = true;
  },
  [types.RECEIVE_DEPENDENCIES_ERROR](state) {
    state.isLoading = false;
    state.errorLoading = true;
    state.dependencies = [];
    state.pageInfo = {};
    state.initialized = true;
  },
  [types.SET_REPORT_STATUS](state, payload) {
    state.reportStatus = payload;
    state.initialized = true;
  },
  [types.SET_SORT_FIELD](state, payload) {
    state.sortField = payload;
  },
  [types.TOGGLE_SORT_ORDER](state) {
    state.sortOrder =
      state.sortOrder === SORT_ORDER.ascending ? SORT_ORDER.descending : SORT_ORDER.ascending;
  },
};
