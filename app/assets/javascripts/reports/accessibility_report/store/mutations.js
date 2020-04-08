import * as types from './mutation_types';

export default {
  [types.SET_BASE_ENDPOINT](state, endpoint) {
    state.baseEndpoint = endpoint;
  },
  [types.SET_HEAD_ENDPOINT](state, endpoint) {
    state.headEndpoint = endpoint;
  },
  [types.REQUEST_REPORT](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_REPORT_SUCCESS](state, report) {
    state.hasError = false;
    state.isLoading = false;
    state.report = report;
  },
  [types.RECEIVE_REPORT_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
    state.report = {};
  },
};
