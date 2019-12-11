import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_DATA](state, { mergedAtAfter, mergedAtBefore }) {
    state.startDate = mergedAtAfter;
    state.endDate = mergedAtBefore;
  },
  [types.SET_GROUP_NAMESPACE](state, groupNamespace) {
    state.groupNamespace = groupNamespace;
    state.projectPath = null;
  },
  [types.SET_PROJECT_PATH](state, projectPath) {
    state.projectPath = projectPath;
  },
  [types.SET_FILTERS](state, { authorUsername, labelName, milestoneTitle }) {
    state.authorUsername = authorUsername;
    state.labelName = labelName;
    state.milestoneTitle = milestoneTitle;
  },
  [types.SET_DATE_RANGE](state, { startDate, endDate }) {
    state.startDate = startDate;
    state.endDate = endDate;
  },
};
