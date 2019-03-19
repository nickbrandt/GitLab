import * as types from './mutation_types';

export default {
  [types.ADD_PROJECT_TOKEN](state, project) {
    const projectsWithMatchingId = state.projectTokens.filter(token => token.id === project.id);
    if (!projectsWithMatchingId.length) {
      state.projectTokens.push(project);
    }
  },
  [types.DECREMENT_PROJECT_SEARCH_COUNT](state, value) {
    state.searchCount -= value;
  },
  [types.INCREMENT_PROJECT_SEARCH_COUNT](state, value) {
    state.searchCount += value;
  },
  [types.SET_INPUT_VALUE](state, value) {
    state.inputValue = value;
  },
  [types.SET_PROJECT_ENDPOINT_LIST](state, url) {
    state.projectEndpoints.list = url;
  },
  [types.SET_PROJECT_ENDPOINT_ADD](state, url) {
    state.projectEndpoints.add = url;
  },
  [types.SET_PROJECT_SEARCH_RESULTS](state, results) {
    state.projectSearchResults = results;
  },
  [types.SET_PROJECTS](state, projects) {
    state.projects = projects || [];
  },
  [types.SET_PROJECT_TOKENS](state, tokens) {
    state.projectTokens = tokens;
  },
  [types.REMOVE_PROJECT_TOKEN_AT](state, index) {
    state.projectTokens.splice(index, 1);
  },
  [types.TOGGLE_IS_LOADING_PROJECTS](state) {
    state.isLoadingProjects = !state.isLoadingProjects;
  },
};
