import * as types from './mutation_types';

// eslint-disable-next-line import/prefer-default-export
export const setFilters = ({ commit, dispatch }, { label_name, milestone_title }) => {
  commit(types.SET_FILTERS, { labelName: label_name, milestoneTitle: milestone_title });

  dispatch('mergeRequests/setPage', 1, { root: true });
  dispatch('mergeRequests/fetchMergeRequests', null, { root: true });
};
