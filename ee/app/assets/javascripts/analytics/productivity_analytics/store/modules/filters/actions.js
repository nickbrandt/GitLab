import * as types from './mutation_types';

export const setGroupNamespace = ({ commit, dispatch }, groupNamespace) => {
  commit(types.SET_GROUP_NAMESPACE, groupNamespace);

  // let's fetch the merge requests first to see if the user has access to the selected group
  // if there's no 403, then we fetch all chart data
  return dispatch('table/fetchMergeRequests', null, { root: true }).then(() =>
    dispatch('charts/fetchAllChartData', null, { root: true }),
  );
};

export const setProjectPath = ({ commit, dispatch }, projectPath) => {
  commit(types.SET_PROJECT_PATH, projectPath);

  dispatch('charts/fetchAllChartData', null, { root: true });
  dispatch('table/fetchMergeRequests', null, { root: true });
};

export const setPath = ({ commit, dispatch }, path) => {
  commit(types.SET_PATH, path);

  dispatch('charts/fetchAllChartData', null, { root: true });
  dispatch('table/fetchMergeRequests', null, { root: true });
};

export const setDaysInPast = ({ commit, dispatch }, days) => {
  commit(types.SET_DAYS_IN_PAST, days);

  dispatch('charts/fetchAllChartData', null, { root: true });
  dispatch('table/fetchMergeRequests', null, { root: true });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
