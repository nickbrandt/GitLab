import * as types from './mutation_types';

export default {
  [types.SET_ENDPOINT](state, endpoint) {
    state.environmentsEndpoint = endpoint;
  },
  [types.REQUEST_ENVIRONMENTS](state) {
    state.isLoadingEnvironments = true;
    state.errorLoadingEnvironments = false;
  },
  [types.RECEIVE_ENVIRONMENTS_SUCCESS](state, payload) {
    state.environments = payload;
    state.isLoadingEnvironments = false;
    state.errorLoadingEnvironments = false;
  },
  [types.RECEIVE_ENVIRONMENTS_ERROR](state) {
    state.isLoadingEnvironments = false;
    state.errorLoadingEnvironments = true;
  },
  [types.SET_CURRENT_ENVIRONMENT_ID](state, payload) {
    state.currentEnvironmentId = payload;
  },
  [types.SET_CURRENT_TIME_WINDOW](state, payload) {
    state.currentTimeWindow = payload;
  },
};
