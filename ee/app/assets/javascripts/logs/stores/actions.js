import Api from 'ee/api';
import { backOff } from '~/lib/utils/common_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { s__ } from '~/locale';
import * as types from './mutation_types';

const requestLogsUntilData = ({ projectPath, environmentId, podName }) =>
  backOff((next, stop) => {
    Api.getPodLogs({ projectPath, environmentId, podName })
      .then(res => {
        if (res.status === httpStatusCodes.ACCEPTED) {
          next();
          return;
        }
        stop(res);
      })
      .catch(err => {
        stop(err);
      });
  });

export const setInitData = ({ dispatch, commit }, { projectPath, environmentId, podName }) => {
  commit(types.SET_PROJECT_ENVIRONMENT, { projectPath, environmentId });
  commit(types.SET_CURRENT_POD_NAME, podName);
  dispatch('fetchLogs');
};

export const showPodLogs = ({ dispatch, commit }, podName) => {
  commit(types.SET_CURRENT_POD_NAME, podName);
  dispatch('fetchLogs');
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

export const fetchLogs = ({ commit, state }) => {
  const params = {
    projectPath: state.projectPath,
    environmentId: state.environments.current,
    podName: state.pods.current,
  };

  commit(types.REQUEST_PODS_DATA);
  commit(types.REQUEST_LOGS_DATA);

  return requestLogsUntilData(params)
    .then(({ data }) => {
      const { pod_name, pods, logs } = data;
      commit(types.SET_CURRENT_POD_NAME, pod_name);

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
