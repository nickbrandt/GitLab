import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { __, s__, sprintf } from '~/locale';
import * as types from './mutation_types';

const API_MINIMUM_QUERY_LENGTH = 3;

export const toggleSelectedProject = ({ commit, state }, project) => {
  const isProject = ({ id }) => id === project.id;

  if (state.selectedProjects.some(isProject)) {
    commit(types.DESELECT_PROJECT, project);
  } else {
    commit(types.SELECT_PROJECT, project);
  }
};

export const clearSearchResults = ({ commit }) => {
  commit(types.CLEAR_SEARCH_RESULTS);
};

export const setSearchQuery = ({ commit }, query) => {
  commit(types.SET_SEARCH_QUERY, query);
};

export const setProjectEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_PROJECT_ENDPOINTS, endpoints);
};

export const addProjects = ({ state, dispatch }) => {
  dispatch('requestAddProjects');

  return axios
    .post(state.projectEndpoints.add, {
      project_ids: state.selectedProjects.map(p => p.id),
    })
    .then(response => dispatch('receiveAddProjectsSuccess', response.data))
    .catch(() => dispatch('receiveAddProjectsError'));
};

export const requestAddProjects = ({ commit }) => {
  commit(types.REQUEST_ADD_PROJECTS);
};

export const receiveAddProjectsSuccess = ({ commit, dispatch, state }, data) => {
  const { added, invalid } = data;

  commit(types.RECEIVE_ADD_PROJECTS_SUCCESS);

  if (invalid.length) {
    const [firstProject, secondProject, ...rest] = state.selectedProjects
      .filter(project => invalid.includes(project.id))
      .map(project => project.name);
    const translationValues = {
      firstProject,
      secondProject,
      rest: rest.join(', '),
    };
    let invalidProjects;
    if (rest.length > 0) {
      invalidProjects = sprintf(
        s__('SecurityDashboard|%{firstProject}, %{secondProject}, and %{rest}'),
        translationValues,
      );
    } else if (secondProject) {
      invalidProjects = sprintf(
        s__('SecurityDashboard|%{firstProject} and %{secondProject}'),
        translationValues,
      );
    } else {
      invalidProjects = firstProject;
    }
    createFlash(
      sprintf(s__('SecurityDashboard|Unable to add %{invalidProjects}'), {
        invalidProjects,
      }),
    );
  }

  if (added.length) {
    dispatch('fetchProjects');
  }
};

export const receiveAddProjectsError = ({ commit }) => {
  commit(types.RECEIVE_ADD_PROJECTS_ERROR);

  createFlash(__('Something went wrong, unable to add projects to dashboard'));
};

export const fetchProjects = ({ state, dispatch }) => {
  dispatch('requestProjects');

  return axios
    .get(state.projectEndpoints.list)
    .then(({ data }) => {
      dispatch('receiveProjectsSuccess', data);
    })
    .catch(() => dispatch('receiveProjectsError'));
};

export const requestProjects = ({ commit }) => {
  commit(types.REQUEST_PROJECTS);
};

export const receiveProjectsSuccess = ({ commit }, { projects }) => {
  commit(types.RECEIVE_PROJECTS_SUCCESS, projects);
};

export const receiveProjectsError = ({ commit }) => {
  commit(types.RECEIVE_PROJECTS_ERROR);

  createFlash(__('Something went wrong, unable to get projects'));
};

export const removeProject = ({ dispatch }, removePath) => {
  dispatch('requestRemoveProject');

  return axios
    .delete(removePath)
    .then(() => {
      dispatch('receiveRemoveProjectSuccess');
    })
    .catch(() => dispatch('receiveRemoveProjectError'));
};

export const requestRemoveProject = ({ commit }) => {
  commit(types.REQUEST_REMOVE_PROJECT);
};

export const receiveRemoveProjectSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_REMOVE_PROJECT_SUCCESS);
  dispatch('fetchProjects');
};

export const receiveRemoveProjectError = ({ commit }) => {
  commit(types.RECEIVE_REMOVE_PROJECT_ERROR);

  createFlash(__('Something went wrong, unable to remove project'));
};

export const fetchSearchResults = ({ state, dispatch }) => {
  const { searchQuery } = state;
  dispatch('requestSearchResults');

  if (!searchQuery || searchQuery.length < API_MINIMUM_QUERY_LENGTH) {
    return dispatch('setMinimumQueryMessage');
  }

  return Api.projects(searchQuery, {})
    .then(results => dispatch('receiveSearchResultsSuccess', results))
    .catch(() => dispatch('receiveSearchResultsError'));
};

export const requestSearchResults = ({ commit }) => {
  commit(types.REQUEST_SEARCH_RESULTS);
};

export const receiveSearchResultsSuccess = ({ commit }, results) => {
  commit(types.RECEIVE_SEARCH_RESULTS_SUCCESS, results);
};

export const receiveSearchResultsError = ({ commit }) => {
  commit(types.RECEIVE_SEARCH_RESULTS_ERROR);
};

export const setMinimumQueryMessage = ({ commit }) => {
  commit(types.SET_MINIMUM_QUERY_MESSAGE);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
