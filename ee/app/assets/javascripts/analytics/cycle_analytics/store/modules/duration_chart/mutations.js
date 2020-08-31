import * as types from './mutation_types';

export default {
  [types.SET_LOADING](state, loading) {
    state.isLoading = loading;
  },
  [types.UPDATE_SELECTED_DURATION_CHART_STAGES](state, { updatedDurationStageData }) {
    state.durationData = updatedDurationStageData;
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
};
