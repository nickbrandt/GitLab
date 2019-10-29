import { backOff } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { s__ } from '~/locale';
import * as types from './mutation_types';

const requestUntilData = (url, params) =>
  backOff((next, stop) => {
    axios
      .get(url, {
        params,
      })
      .then(res => {
        if (!res.data) {
          next();
          return;
        }
        stop(res);
      })
      .catch(err => {
        stop(err);
      });
  });

export const setLogsEndpoint = ({ commit }, logsEndpoint) => {
  commit(types.SET_LOGS_ENDPOINT, logsEndpoint);
};

export const fetchEnvironments = ({ commit }, environmentsPath) => {
  commit(types.REQUEST_ENVIRONMENTS_DATA);

  axios
    .get(environmentsPath)
    .then(({ data }) => {
      commit(types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS, data.environments);
    })
    .catch(() => {
      commit(types.RECEIVE_ENVIRONMENTS_DATA_ERROR);
      flash(s__('Metrics|There was an error fetching the environments data, please try again'));
    });
};

export const fetchLogs = ({ commit, state }, podName) => {
  if (podName) {
    commit(types.SET_CURRENT_POD_NAME, podName);
  }
  commit(types.REQUEST_PODS_DATA);
  commit(types.REQUEST_LOGS_DATA);
  return requestUntilData(state.logs.endpoint, { pod_name: podName })
    .then(({ data }) => {
      const { pods, logs } = data;

      // Set first pod as default, if none is set
      if (!podName && pods[0]) {
        commit(types.SET_CURRENT_POD_NAME, pods[0]);
      }

      commit(types.RECEIVE_PODS_DATA_SUCCESS, pods);
      commit(types.RECEIVE_LOGS_DATA_SUCCESS, logs);
    })
    .catch(() => {
      commit(types.RECEIVE_PODS_DATA_ERROR);
      commit(types.RECEIVE_LOGS_DATA_ERROR);
      flash(s__('Metrics|There was an error fetching the logs, please try again'));
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
