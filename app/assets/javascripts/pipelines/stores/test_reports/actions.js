import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import createFlash from '~/flash';
import { s__ } from '~/locale';

export const fetchSummary = ({ dispatch, state, commit }) => {
  dispatch('setLoading', true);

  return axios
    .get(state.summaryEndpoint)
    .then(({ data }) => {
      commit(types.SET_SUMMARY, data);

      // Set the tab counter badge to total_count
      // This is temporary until we can server-side render that count number
      // (see https://gitlab.com/gitlab-org/gitlab/-/issues/223134)
      if (data.total_count !== undefined) {
        document.querySelector('.js-test-report-badge-counter').innerHTML = data.total_count;
      }
    })
    .catch(() => {
      createFlash(s__('TestReports|There was an error fetching the summary.'));
    })
    .finally(() => {
      dispatch('setLoading', false);
    });
};

export const fetchFullReport = ({ state, commit, dispatch }) => {
  dispatch('setLoading', true);

  return axios
    .get(state.fullReportEndpoint)
    .then(({ data }) => commit(types.SET_REPORTS, data))
    .catch(() => {
      createFlash(s__('TestReports|There was an error fetching the test reports.'));
    })
    .finally(() => {
      dispatch('setLoading', false);
    });
};

export const setSelectedSuite = ({ commit, dispatch, state }, index) => {
  commit(types.SET_SELECTED_SUITE, index);

  // Fetch the full report when the user clicks to see more details
  if (!state.hasFullReport) {
    dispatch('fetchFullReport');
  }
};
export const removeSelectedSuite = ({ commit }) => commit(types.SET_SELECTED_SUITE, null);
export const setLoading = ({ commit }, isLoading) => commit(types.SET_LOADING, isLoading);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
