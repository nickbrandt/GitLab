import createFlash from '~/flash';
import { vuexApolloClient } from 'ee/security_dashboard/graphql/provider';
import { __, s__, sprintf } from '~/locale';
import * as types from './mutation_types';
import { PROJECTS_PER_PAGE } from './constants';
import getProjects from 'ee/security_dashboard/graphql/get_projects.query.graphql';
import getInstanceSecurityDashboardProjects from 'ee/security_dashboard/graphql/get_instance_security_dashboard_projects.query.graphql';
import addProjectToSecurityDashboard from 'ee/security_dashboard/graphql/add_project_to_security_dashboard.mutation.graphql';
import deleteProjectFromSecurityDashboard from 'ee/security_dashboard/graphql/delete_project_from_security_dashboard.mutation.graphql';
import { processAddProjectResponse } from './utils';

const API_MINIMUM_QUERY_LENGTH = 3;

const searchProjects = (searchQuery, pageInfo) => {
  return vuexApolloClient.query({
    query: getProjects,
    variables: { search: searchQuery, first: PROJECTS_PER_PAGE, after: pageInfo.endCursor },
  });
};

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

export const addProjects = ({ state, dispatch }) => {
  dispatch('requestAddProjects');

  const addProjectsPromises = state.selectedProjects.map(p => {
    return vuexApolloClient
      .mutate({ mutation: addProjectToSecurityDashboard, variables: { id: p.id } })
      .catch(() => dispatch('receiveAddProjectsError'));
  });

  return Promise.all(addProjectsPromises)
    .then(response => {
      const projects = processAddProjectResponse(response, state.selectedProjects);
      return dispatch('receiveAddProjectsSuccess', projects);
    })
    .finally(() => dispatch('clearSearchResults'));
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
        s__('SecurityReports|%{firstProject}, %{secondProject}, and %{rest}'),
        translationValues,
      );
    } else if (secondProject) {
      invalidProjects = sprintf(
        s__('SecurityReports|%{firstProject} and %{secondProject}'),
        translationValues,
      );
    } else {
      invalidProjects = firstProject;
    }
    createFlash(
      sprintf(s__('SecurityReports|Unable to add %{invalidProjects}'), {
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

export const fetchProjects = ({ dispatch }) => {
  dispatch('requestProjects');

  return vuexApolloClient
    .query({
      query: getInstanceSecurityDashboardProjects,
    })
    .then(({ data: { instanceSecurityDashboard: { projects: { nodes: projects } } } }) => {
      dispatch('receiveProjectsSuccess', { projects });
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

export const removeProject = ({ dispatch }, projectId) => {
  dispatch('requestRemoveProject');

  vuexApolloClient
    .mutate({
      mutation: deleteProjectFromSecurityDashboard,
      variables: { id: projectId },
    })
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

export const fetchSearchResults = ({ state, dispatch, commit }) => {
  const { searchQuery } = state;
  dispatch('requestSearchResults');

  if (!searchQuery || searchQuery.length < API_MINIMUM_QUERY_LENGTH) {
    return dispatch('setMinimumQueryMessage');
  }

  return searchProjects(searchQuery, state.pageInfo)
    .then(payload => {
      const {
        data: {
          projects: { nodes, pageInfo },
        },
      } = payload;
      return commit(types.RECEIVE_SEARCH_RESULTS_SUCCESS, { data: nodes, pageInfo });
    })
    .catch(() => dispatch('receiveSearchResultsError'));
};

export const fetchSearchResultsNextPage = ({ state, dispatch, commit }) => {
  const {
    searchQuery,
    pageInfo: { hasNextPage, endCursor },
  } = state;

  if (!hasNextPage) {
    return Promise.resolve();
  }

  return searchProjects(searchQuery, { hasNextPage, endCursor })
    .then(payload => {
      const {
        data: {
          projects: { nodes, pageInfo },
        },
      } = payload;
      commit(types.RECEIVE_NEXT_PAGE_SUCCESS, { data: nodes, pageInfo });
    })
    .catch(() => dispatch('receiveSearchResultsError'));
};

export const requestSearchResults = ({ commit }) => {
  commit(types.REQUEST_SEARCH_RESULTS);
};

export const receiveSearchResultsError = ({ commit }) => {
  commit(types.RECEIVE_SEARCH_RESULTS_ERROR);
};

export const setMinimumQueryMessage = ({ commit }) => {
  commit(types.SET_MINIMUM_QUERY_MESSAGE);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
