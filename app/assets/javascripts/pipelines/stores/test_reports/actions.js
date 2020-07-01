import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import createFlash from '~/flash';
import { s__ } from '~/locale';

export const fetchSummary = ({ state, commit, dispatch }) => {
  dispatch('toggleLoading');

  return axios
    .get(state.summaryEndpoint)
    .then(response => {
      const { data } = response;
      commit(types.SET_SUMMARY, data);
    })
    .catch(() => {
      createFlash(s__('TestReports|There was an error fetching the test report summary.'));
    })
    .finally(() => {
      dispatch('toggleLoading');
    });
};

export const fetchFullReport = ({ state, commit, dispatch }) => {
  dispatch('toggleLoading');

  return axios
    .get(state.fullReportEndpoint)
    .then(response => {
      const { data } = response;
      commit(types.SET_REPORTS, data);
    })
    .catch(() => {
      createFlash(s__('TestReports|There was an error fetching the test reports.'));
    })
    .finally(() => {
      dispatch('toggleLoading');
    });
};

export const setSelectedSuite = ({ commit, dispatch, state }, data) => {
  if (!state.hasFullReport) {
    dispatch('fetchFullReport');
  }

  commit(types.SET_SELECTED_SUITE, data);
};
export const removeSelectedSuite = ({ commit }) => commit(types.SET_SELECTED_SUITE, {});
export const toggleLoading = ({ commit }) => commit(types.TOGGLE_LOADING);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
