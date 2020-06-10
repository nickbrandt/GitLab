import * as types from '../mutation_types';

export default {
  [types.SET_CURRENT_PROJECT](state, currentProjectId) {
    Object.assign(state, {
      currentProjectId,
    });
  },
  [types.SET_PROJECT](state, project) {
    Object.assign(project, {
      branches: {},
      mergeRequests: {},
      active: true,
    });

    Object.assign(state, {
      project,
    });
  },
  [types.TOGGLE_EMPTY_STATE](state, { value }) {
    Object.assign(state.project, {
      empty_repo: value,
    });
  },
};
