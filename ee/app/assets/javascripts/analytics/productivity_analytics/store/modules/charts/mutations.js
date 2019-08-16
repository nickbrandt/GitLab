import * as types from './mutation_types';

export default {
  [types.RESET_CHART_DATA](state, chartKey) {
    state.charts[chartKey].data = {};
    state.charts[chartKey].selected = [];
  },
  [types.REQUEST_CHART_DATA](state, chartKey) {
    state.charts[chartKey].isLoading = true;
  },
  [types.RECEIVE_CHART_DATA_SUCCESS](state, { chartKey, data }) {
    state.charts[chartKey].isLoading = false;
    state.charts[chartKey].hasError = false;
    state.charts[chartKey].data = data;
  },
  [types.RECEIVE_CHART_DATA_ERROR](state, chartKey) {
    state.charts[chartKey].isLoading = false;
    state.charts[chartKey].hasError = true;
    state.charts[chartKey].data = {};
  },
  [types.SET_METRIC_TYPE](state, { chartKey, metricType }) {
    state.charts[chartKey].params.metricType = metricType;
  },
  [types.UPDATE_SELECTED_CHART_ITEMS](state, { chartKey, item }) {
    const idx = state.charts[chartKey].selected.indexOf(item);
    if (idx === -1) {
      state.charts[chartKey].selected.push(item);
    } else {
      state.charts[chartKey].selected.splice(idx, 1);
    }
  },
};
