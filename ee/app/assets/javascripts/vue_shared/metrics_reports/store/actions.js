import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export const setEndpoint = ({ commit }, endpoint) => commit(types.SET_ENDPOINT, endpoint);

export const requestMetrics = ({ commit }) => commit(types.REQUEST_METRICS);

export const fetchMetrics = ({ state, dispatch }) => {
  dispatch('requestMetrics');

  return axios
    .get(state.endpoint)
    .then(response => dispatch('receiveMetricsSuccess', response.data))
    .catch(() => dispatch('receiveMetricsError'));
};

export const receiveMetricsSuccess = ({ commit }, response) => {
  commit(types.RECEIVE_METRICS_SUCCESS, response);
};

export const receiveMetricsError = ({ commit }) => commit(types.RECEIVE_METRICS_ERROR);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
