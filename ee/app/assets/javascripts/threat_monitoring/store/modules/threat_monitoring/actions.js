import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import * as types from './mutation_types';

export const setEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_ENDPOINT, endpoints.environmentsEndpoint);
  commit(`threatMonitoringWaf/${types.SET_ENDPOINT}`, endpoints.wafStatisticsEndpoint, {
    root: true,
  });
  commit(
    `threatMonitoringNetworkPolicy/${types.SET_ENDPOINT}`,
    endpoints.networkPolicyStatisticsEndpoint,
    { root: true },
  );
};

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
  dispatch(`threatMonitoringWaf/fetchStatistics`, null, { root: true });
  dispatch(`threatMonitoringNetworkPolicy/fetchStatistics`, null, { root: true });
  if (window.gon.features?.networkPolicyManagement) {
    dispatch(`networkPolicies/fetchPolicies`, environmentId, { root: true });
  }
};

export const setCurrentTimeWindow = ({ commit, dispatch }, timeWindow) => {
  commit(types.SET_CURRENT_TIME_WINDOW, timeWindow.name);
  dispatch(`threatMonitoringWaf/fetchStatistics`, null, { root: true });
  dispatch(`threatMonitoringNetworkPolicy/fetchStatistics`, null, { root: true });
};
