import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import { chartKeys } from '../../../constants';

export const fetchAllChartData = ({ commit, state, dispatch }) => {
  // let's reset any data on the main chart first
  // since any selected items will be used as query params for other charts)
  commit(types.RESET_CHART_DATA, chartKeys.main);

  Object.keys(state.charts).forEach(chartKey => {
    dispatch('fetchChartData', chartKey);
  });
};

export const requestChartData = ({ commit }, chartKey) =>
  commit(types.REQUEST_CHART_DATA, chartKey);

export const fetchChartData = ({ dispatch, getters, rootState }, chartKey) => {
  dispatch('requestChartData', chartKey);

  const params = getters.getFilterParams(chartKey);

  return axios
    .get(rootState.endpoint, { params })
    .then(response => {
      const { data } = response;
      dispatch('receiveChartDataSuccess', { chartKey, data });
    })
    .catch(error => dispatch('receiveChartDataError', { chartKey, error }));
};

export const receiveChartDataSuccess = ({ commit }, { chartKey, data = {} }) => {
  commit(types.RECEIVE_CHART_DATA_SUCCESS, { chartKey, data });
};

export const receiveChartDataError = ({ commit }, { chartKey, error }) => {
  const {
    response: { status },
  } = error;
  commit(types.RECEIVE_CHART_DATA_ERROR, { chartKey, status });
};

export const setMetricType = ({ commit, dispatch }, { chartKey, metricType }) => {
  commit(types.SET_METRIC_TYPE, { chartKey, metricType });

  dispatch('fetchChartData', chartKey);
};

export const chartItemClicked = ({ commit, dispatch }, { chartKey, item }) => {
  commit(types.UPDATE_SELECTED_CHART_ITEMS, { chartKey, item });

  // update histograms
  dispatch('fetchChartData', chartKeys.timeBasedHistogram);
  dispatch('fetchChartData', chartKeys.commitBasedHistogram);

  // TODO: update scatterplot

  // update table
  dispatch('table/fetchMergeRequests', null, { root: true });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
