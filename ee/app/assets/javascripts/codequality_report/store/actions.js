import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import createFlash from '~/flash';
import { s__ } from '~/locale';

import MergeRequestStore from 'ee/vue_merge_request_widget/stores/mr_widget_store';

export const setEndpoint = ({ commit }, data) => commit(types.SET_ENDPOINT, data);
export const setBlobPath = ({ commit }, data) => commit(types.SET_BLOB_PATH, data);

export const setPage = ({ commit }, page) => commit(types.SET_PAGE, page);

export const requestReport = ({ commit }) => commit(types.REQUEST_REPORT);
export const receiveReportSuccess = ({ state, commit }, data) => {
  const parsedIssues = MergeRequestStore.parseCodeclimateMetrics(data, state.blobPath);
  commit(types.RECEIVE_REPORT_SUCCESS, parsedIssues);
};
export const receiveReportError = ({ commit }, error) => commit(types.RECEIVE_REPORT_ERROR, error);

export const fetchReport = ({ state, dispatch }) => {
  dispatch('requestReport');

  axios
    .get(state.endpoint)
    .then(({ data }) => {
      if (!state.blobPath) throw new Error();
      dispatch('receiveReportSuccess', data);
    })
    .catch(error => {
      dispatch('receiveReportError', error);
      createFlash(s__('ciReport|There was an error fetching the codequality report.'));
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
