import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_PAGE_DATA](state, data) {
    const { configEndpoint, reportId, groupName, groupPath } = data;

    state.configEndpoint = configEndpoint;
    state.reportId = reportId;
    state.groupName = groupName;
    state.groupPath = groupPath;
  },
  [types.REQUEST_PAGE_CONFIG_DATA](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_PAGE_CONFIG_DATA_SUCCESS](state, data) {
    state.isLoading = false;
    state.config = data;
  },
  [types.RECEIVE_PAGE_CONFIG_DATA_ERROR](state) {
    state.isLoading = false;
  },
};
