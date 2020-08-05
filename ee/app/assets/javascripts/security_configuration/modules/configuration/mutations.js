import * as types from './mutation_types';

export default {
  [types.SET_SECURITY_CONFIGURATION_ENDPOINT](state, payload) {
    state.securityConfigurationPath = payload;
  },
  [types.REQUEST_SECURITY_CONFIGURATION](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_SECURITY_CONFIGURATION_SUCCESS](state, payload) {
    state.isLoading = false;
    state.pipelineJobs = payload;
  },
  [types.RECEIVE_SECURITY_CONFIGURATION_ERROR](state) {
    state.isLoading = false;
  },
};
