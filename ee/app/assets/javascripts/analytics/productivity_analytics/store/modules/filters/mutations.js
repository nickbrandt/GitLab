import * as types from './mutation_types';

export default {
  [types.SET_GROUP_NAMESPACE](state, groupNamespace) {
    state.groupNamespace = groupNamespace;
    state.projectPath = null;
  },
  [types.SET_PROJECT_PATH](state, projectPath) {
    state.projectPath = projectPath;
  },
  [types.SET_PATH](state, path) {
    state.filters = path;
  },
  [types.SET_DAYS_IN_PAST](state, daysInPast) {
    state.daysInPast = daysInPast;
  },
};
