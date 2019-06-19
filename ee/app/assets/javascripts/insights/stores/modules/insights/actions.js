import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { __ } from '~/locale';

export const requestConfig = ({ commit }) => commit(types.REQUEST_CONFIG);
export const receiveConfigSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_CONFIG_SUCCESS, data);
export const receiveConfigError = ({ commit }) => commit(types.RECEIVE_CONFIG_ERROR);

export const fetchConfigData = ({ dispatch }, endpoint) => {
  dispatch('requestConfig');

  return axios
    .get(endpoint)
    .then(({ data }) => dispatch('receiveConfigSuccess', data))
    .catch(error => {
      const message = `${__('There was an error fetching configuration for charts')}: ${
        error.response.data.message
      }`;
      createFlash(message);
      dispatch('receiveConfigError');
    });
};

export const receiveChartDataSuccess = ({ commit }, { chart, data }) =>
  commit(types.RECEIVE_CHART_SUCCESS, { chart, data });
export const receiveChartDataError = ({ commit }, { chart, error }) =>
  commit(types.RECEIVE_CHART_ERROR, { chart, error });

export const fetchChartData = ({ dispatch }, { endpoint, chart }) =>
  axios
    .post(endpoint, {
      query: chart.query,
      chart_type: chart.type,
    })
    .then(({ data }) => dispatch('receiveChartDataSuccess', { chart, data }))
    .catch(error => {
      let message = `${__('There was an error gathering the chart data')}`;

      if (error.response.data && error.response.data.message) {
        message += `: ${error.response.data.message}`;
      }
      createFlash(message);
      dispatch('receiveChartDataError', { chart, error: message });
    });

export const setActiveTab = ({ commit, state }, key) => {
  const { configData } = state;

  const page = configData[key];

  commit(types.SET_ACTIVE_TAB, key);
  commit(types.SET_ACTIVE_PAGE, page);
};

export const initChartData = ({ commit }, store) => commit(types.INIT_CHART_DATA, store);
export const setPageLoading = ({ commit }, pageLoading) =>
  commit(types.SET_PAGE_LOADING, pageLoading);

export default () => {};
