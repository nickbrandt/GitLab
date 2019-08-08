import * as types from './mutation_types';

export const setGroupNamespace = ({ commit, dispatch }, groupNamespace) => {
  commit(types.SET_GROUP_NAMESPACE, groupNamespace);

  dispatch('table/fetchMergeRequests', null, { root: true });
};

export const setProjectPath = ({ commit, dispatch }, projectPath) => {
  commit(types.SET_PROJECT_PATH, projectPath);

  dispatch('table/fetchMergeRequests', null, { root: true });
};

export const setPath = ({ commit, dispatch }, path) => {
  commit(types.SET_PATH, path);

  dispatch('table/fetchMergeRequests', null, { root: true });
};

export const setDaysInPast = ({ commit, dispatch }, days) => {
  commit(types.SET_DAYS_IN_PAST, days);

  dispatch('table/fetchMergeRequests', null, { root: true });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
