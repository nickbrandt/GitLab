import Visibility from 'visibilityjs';
import Poll from '~/lib/utils/poll';
import httpStatusCodes from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import { s__ } from '~/locale';

let eTagPoll;

export const clearEtagPoll = () => {
  eTagPoll = null;
};

export const stopPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};

export const restartPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};

export const setEndpoint = ({ commit }, endpoint) => commit(types.SET_ENDPOINT, endpoint);

/**
 * We need to poll the report endpoint while they are being parsed in the Backend.
 * This can take up to one minute.
 *
 * Poll.js will handle etag response.
 * While http status code is 204, it means it's parsing, and we'll keep polling
 * When http status code is 200, it means parsing is done, we can show the results & stop polling
 * When http status code is 500, it means parsing went wrong and we stop polling
 */
export const fetchReport = ({ state, dispatch, commit }) => {
  commit(types.REQUEST_REPORT);

  eTagPoll = new Poll({
    resource: {
      getReport(endpoint) {
        return axios.get(endpoint);
      },
    },
    data: state.endpoint,
    method: 'getReport',
    successCallback: ({ status, data }) => dispatch('receiveReportSuccess', { status, data }),
    errorCallback: () => dispatch('receiveReportError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  } else {
    axios
      .get(state.endpoint)
      .then(({ status, data }) => dispatch('receiveReportSuccess', { status, data }))
      .catch(() => dispatch('receiveReportError'));
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartPolling');
    } else {
      dispatch('stopPolling');
    }
  });
};

export const receiveReportSuccess = ({ commit }, response) => {
  if (response.status === httpStatusCodes.OK) {
    const report = response.data;
    commit(types.RECEIVE_REPORT_SUCCESS, report);
  }
};

export const receiveReportError = ({ commit }) => {
  commit(
    types.RECEIVE_REPORT_ERROR,
    s__('AccessibilityReport|Failed to retrieve accessibility report'),
  );
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
