import * as types from './mutation_types';

export default {
  [types.SET_PROJECTS_ENDPOINT](state, payload) {
    state.projectsEndpoint = payload;
  },
  [types.REQUEST_PROJECTS](state) {
    state.isLoadingProjects = true;
    state.errorLoadingProjects = false;
  },
  [types.RECEIVE_PROJECTS_SUCCESS](state, payload) {
    state.projects = payload.projects;
    state.isLoadingProjects = false;
  },
  [types.RECEIVE_PROJECTS_ERROR](state) {
    state.isLoadingProjects = false;
    state.errorLoadingProjects = true;
  },
};
