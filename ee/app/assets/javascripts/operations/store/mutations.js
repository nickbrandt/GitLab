import _ from 'underscore';
import * as types from './mutation_types';

export default {
  [types.SET_PROJECT_ENDPOINT_LIST](state, url) {
    state.projectEndpoints.list = url;
  },
  [types.SET_PROJECT_ENDPOINT_ADD](state, url) {
    state.projectEndpoints.add = url;
  },
  [types.SET_PROJECTS](state, projects) {
    state.projects = projects || [];
    state.isLoadingProjects = false;
  },
  [types.SET_SEARCH_QUERY](state, query) {
    state.searchQuery = query;
  },

  [types.SET_MESSAGE_MINIMUM_QUERY](state, bool) {
    state.messages.minimumQuery = bool;
  },

  [types.ADD_SELECTED_PROJECT](state, project) {
    if (!state.selectedProjects.some(p => p.id === project.id)) {
      state.selectedProjects.push(project);
    }
  },
  [types.REMOVE_SELECTED_PROJECT](state, project) {
    state.selectedProjects = _.without(
      state.selectedProjects,
      ..._.where(state.selectedProjects, { id: project.id }),
    );
  },

  [types.REQUEST_PROJECTS](state) {
    state.isLoadingProjects = true;
  },
  [types.RECEIVE_PROJECTS_SUCCESS](state, projects) {
    state.projects = projects;
    state.isLoadingProjects = false;
  },
  [types.RECEIVE_PROJECTS_ERROR](state) {
    state.projects = null;
    state.isLoadingProjects = false;
  },

  [types.CLEAR_SEARCH_RESULTS](state) {
    state.projectSearchResults = [];
    state.selectedProjects = [];
  },

  [types.REQUEST_SEARCH_RESULTS](state) {
    // Flipping this property separately to allows the UI
    // to hide the "minimum query" message
    // before the seach results arrive from the API
    state.messages.minimumQuery = false;

    state.searchCount += 1;
  },
  [types.RECEIVE_SEARCH_RESULTS_SUCCESS](state, results) {
    state.projectSearchResults = results;
    state.messages.noResults = state.projectSearchResults.length === 0;
    state.messages.searchError = false;
    state.messages.minimumQuery = false;
    state.searchCount -= 1;
  },
  [types.RECEIVE_SEARCH_RESULTS_ERROR](state, message) {
    state.projectSearchResults = [];
    state.messages.noResults = false;
    state.messages.searchError = true;
    state.messages.minimumQuery = message === 'minimumQuery';
    state.searchCount -= 1;
  },
};
