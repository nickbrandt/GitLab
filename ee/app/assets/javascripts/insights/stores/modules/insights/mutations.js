import * as types from './mutation_types';

export default {
  [types.REQUEST_CONFIG](state) {
    state.configData = null;
    state.configLoading = true;
  },
  [types.RECEIVE_CONFIG_SUCCESS](state, data) {
    state.configData = data;
    state.configLoading = false;
  },
  [types.RECEIVE_CONFIG_ERROR](state) {
    state.configData = null;
    state.configLoading = false;
  },

  [types.REQUEST_CHART](state) {
    state.chartData = null;
    state.chartLoading = true;
  },
  [types.RECEIVE_CHART_SUCCESS](state, data) {
    state.chartData = data;
    state.chartLoading = false;
    state.redraw = true;
  },
  [types.RECEIVE_CHART_ERROR](state) {
    state.chartData = null;
    state.chartLoading = false;
  },

  [types.SET_ACTIVE_TAB](state, tab) {
    state.activeTab = tab;
  },
  [types.SET_ACTIVE_CHART](state, chartData) {
    state.activeChart = chartData;
  },
};
