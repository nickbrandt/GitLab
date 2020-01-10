import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import pollUntilComplete from '~/lib/utils/poll_until_complete';
import httpStatusCodes from '~/lib/utils/http_status';
import createFlash from '~/flash';
import * as types from './mutation_types';
import createState from './state';
import { getTimeWindowParams } from './utils';

export const setEndpoints = ({ commit }, endpoints) => commit(types.SET_ENDPOINTS, endpoints);

export const requestEnvironments = ({ commit }) => commit(types.REQUEST_ENVIRONMENTS);
export const receiveEnvironmentsSuccess = ({ commit }, environments) =>
  commit(types.RECEIVE_ENVIRONMENTS_SUCCESS, environments);
export const receiveEnvironmentsError = ({ commit }) => {
  commit(types.RECEIVE_ENVIRONMENTS_ERROR);
  createFlash(s__('ThreatMonitoring|Something went wrong, unable to fetch environments'));
};

const getAllEnvironments = (url, page = 1) =>
  axios
    .get(url, {
      params: {
        per_page: 100,
        page,
      },
    })
    .then(({ headers, data }) => {
      const nextPage = headers && headers['x-next-page'];
      return nextPage
        ? // eslint-disable-next-line promise/no-nesting
          getAllEnvironments(url, nextPage).then(environments => [
            ...data.environments,
            ...environments,
          ])
        : data.environments;
    });

export const fetchEnvironments = ({ state, dispatch }) => {
  if (!state.environmentsEndpoint) {
    return dispatch('receiveEnvironmentsError');
  }

  dispatch('requestEnvironments');

  return getAllEnvironments(state.environmentsEndpoint)
    .then(environments => dispatch('receiveEnvironmentsSuccess', environments))
    .catch(() => dispatch('receiveEnvironmentsError'));
};

export const setCurrentEnvironmentId = ({ commit, dispatch }, environmentId) => {
  commit(types.SET_CURRENT_ENVIRONMENT_ID, environmentId);
  return dispatch('fetchWafStatistics');
};

export const setCurrentTimeWindow = ({ commit, dispatch }, timeWindow) => {
  commit(types.SET_CURRENT_TIME_WINDOW, timeWindow);
  return dispatch('fetchWafStatistics');
};

export const requestWafStatistics = ({ commit }) => commit(types.REQUEST_WAF_STATISTICS);
export const receiveWafStatisticsSuccess = ({ commit }, statistics) =>
  commit(types.RECEIVE_WAF_STATISTICS_SUCCESS, statistics);
export const receiveWafStatisticsError = ({ commit }) => {
  commit(types.RECEIVE_WAF_STATISTICS_ERROR);
  createFlash(s__('ThreatMonitoring|Something went wrong, unable to fetch WAF statistics'));
};

export const fetchWafStatistics = ({ state, dispatch }) => {
  if (!state.wafStatisticsEndpoint) {
    return dispatch('receiveWafStatisticsError');
  }

  dispatch('requestWafStatistics');

  return pollUntilComplete(state.wafStatisticsEndpoint, {
    params: {
      environment_id: state.currentEnvironmentId,
      ...getTimeWindowParams(state.currentTimeWindow, Date.now()),
    },
  })
    .then(({ data }) => dispatch('receiveWafStatisticsSuccess', data))
    .catch(error => {
      // A NOT_FOUND resonse from the endpoint means that there is no data for
      // the given parameters. There are various reasons *why* there could be
      // no data, but we can't distinguish between them, yet. So, just render
      // no data.
      if (error.response.status === httpStatusCodes.NOT_FOUND) {
        dispatch('receiveWafStatisticsSuccess', createState().wafStatistics);
      } else {
        dispatch('receiveWafStatisticsError');
      }
    });
};
