import _ from 'underscore';
import * as types from './mutation_types';

export default {
  [types.DECREMENT_PROJECT_SEARCH_COUNT](state, value) {
    state.searchCount -= value;
  },
  [types.INCREMENT_PROJECT_SEARCH_COUNT](state, value) {
    state.searchCount += value;
  },

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
  [types.REQUEST_PROJECTS](state) {
    state.isLoadingProjects = true;
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

  [types.TOGGLE_IS_LOADING_PROJECTS](state) {
    state.isLoadingProjects = !state.isLoadingProjects;
  },

  [types.CLEAR_SEARCH_RESULTS](state) {
    state.projectSearchResults = [];
    state.selectedProjects = [];
  },

  [types.SEARCHED_WITH_NO_QUERY](state) {
    state.projectSearchResults = [];
    state.messages.noResults = false;
    state.messages.searchError = false;
    state.messages.minimumQuery = false;
  },

  [types.SEARCHED_WITH_TOO_SHORT_QUERY](state) {
    state.projectSearchResults = [];
    state.messages.noResults = false;
    state.messages.searchError = false;
    state.messages.minimumQuery = true;
  },

  [types.SEARCHED_WITH_API_ERROR](state) {
    state.projectSearchResults = [];
    state.messages.noResults = false;
    state.messages.searchError = true;
    state.messages.minimumQuery = false;
  },

  [types.SEARCHED_SUCCESSFULLY_WITH_RESULTS](state, results) {
    state.projectSearchResults = results;
    state.messages.noResults = false;
    state.messages.searchError = false;
    state.messages.minimumQuery = false;
  },

  [types.SEARCHED_SUCCESSFULLY_NO_RESULTS](state) {
    state.projectSearchResults = [];
    state.messages.noResults = true;
    state.messages.searchError = false;
    state.messages.minimumQuery = false;
  },
};
