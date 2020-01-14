import * as types from './mutation_types';

export default {
  [types.SET_PROJECT_ID](state, projectId) {
    state.projectId = projectId;
  },
  [types.SET_FILTERS](state, { labelName, milestoneTitle }) {
    state.filters.labelName = labelName;
    state.filters.milestoneTitle = milestoneTitle;
  },
};
