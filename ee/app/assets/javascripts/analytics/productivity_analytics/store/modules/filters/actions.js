import * as types from './mutation_types';

export const setGroupNamespace = ({ commit }, groupNamespace) => {
  commit(types.SET_GROUP_NAMESPACE, groupNamespace);
};

export const setProjectPath = ({ commit }, projectPath) => {
  commit(types.SET_PROJECT_PATH, projectPath);
};

export const setPath = ({ commit }, path) => {
  commit(types.SET_PATH, path);
};

export const setDaysInPast = ({ commit }, days) => {
  commit(types.SET_DAYS_IN_PAST, days);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
