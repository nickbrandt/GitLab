import * as types from './mutation_types';

export default transformFunc => ({
  [types.SET_ENDPOINT](state, endpoint) {
    state.statisticsEndpoint = endpoint;
  },
  [types.REQUEST_STATISTICS](state, timeRange) {
    state.isLoadingStatistics = true;
    state.errorLoadingStatistics = false;
    state.timeRange = timeRange;
  },
  [types.RECEIVE_STATISTICS_SUCCESS](state, payload) {
    state.statistics = transformFunc(payload);
    state.isLoadingStatistics = false;
    state.errorLoadingStatistics = false;
  },
  [types.RECEIVE_STATISTICS_ERROR](state) {
    state.isLoadingStatistics = false;
    state.errorLoadingStatistics = true;
  },
});
