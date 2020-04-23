import * as types from './mutation_types';

export default {
  [types.SET_FILTERS](state, { labelName, milestoneTitle }) {
    state.labelName = labelName;
    state.milestoneTitle = milestoneTitle;
  },
};
