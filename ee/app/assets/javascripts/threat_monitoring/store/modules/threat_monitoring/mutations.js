import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

export default {
  [types.SET_ENDPOINTS](state, { wafStatisticsEndpoint, environmentsEndpoint }) {
    state.wafStatisticsEndpoint = wafStatisticsEndpoint;
    state.environmentsEndpoint = environmentsEndpoint;
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
  [types.REQUEST_WAF_STATISTICS](state) {
    state.isLoadingWafStatistics = true;
    state.errorLoadingWafStatistics = false;
  },
  [types.RECEIVE_WAF_STATISTICS_SUCCESS](state, payload) {
    state.wafStatistics = convertObjectPropsToCamelCase(payload);
    state.isLoadingWafStatistics = false;
    state.errorLoadingWafStatistics = false;
  },
  [types.RECEIVE_WAF_STATISTICS_ERROR](state) {
    state.isLoadingWafStatistics = false;
    state.errorLoadingWafStatistics = true;
  },
};
