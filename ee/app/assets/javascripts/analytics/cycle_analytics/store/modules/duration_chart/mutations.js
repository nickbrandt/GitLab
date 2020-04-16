import * as types from './mutation_types';

export default {
  [types.UPDATE_SELECTED_DURATION_CHART_STAGES](
    state,
    { updatedDurationStageData, updatedDurationStageMedianData },
  ) {
    state.durationData = updatedDurationStageData;
    state.durationMedianData = updatedDurationStageMedianData;
  },
  [types.REQUEST_DURATION_DATA](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_DURATION_DATA_SUCCESS](state, data) {
    state.durationData = data;
    state.isLoading = false;
  },
  [types.RECEIVE_DURATION_DATA_ERROR](state) {
    state.durationData = [];
    state.isLoading = false;
  },
  [types.RECEIVE_DURATION_MEDIAN_DATA_SUCCESS](state, data) {
    state.durationMedianData = data;
  },
  [types.RECEIVE_DURATION_MEDIAN_DATA_ERROR](state) {
    state.durationMedianData = [];
  },
};
