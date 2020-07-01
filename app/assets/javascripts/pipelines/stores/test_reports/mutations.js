import * as types from './mutation_types';

export default {
  [types.SET_REPORTS](state, testReports) {
    Object.assign(state, { testReports, hasFullReport: true });
  },

  [types.SET_SELECTED_SUITE](state, selectedSuite) {
    Object.assign(state, { selectedSuite });
  },

  [types.SET_SUMMARY](state, summary) {
    // Set the tab counter badge to total_count
    // This is temporary until we can server-side render that count number (see https://gitlab.com/gitlab-org/gitlab/-/issues/223134)
    if (summary.total_count !== undefined) {
      document.querySelector('.js-test-report-badge-counter').innerHTML = summary.total_count;
    }

    Object.assign(state, { summary, testReports: summary });
  },

  [types.TOGGLE_LOADING](state) {
    Object.assign(state, { isLoading: !state.isLoading });
  },
};
