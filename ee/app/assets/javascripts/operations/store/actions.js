import Visibility from 'visibilityjs';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';
import createFlash from '~/flash';
import { __, s__, n__, sprintf } from '~/locale';
import * as types from './mutation_types';

let eTagPoll;

export const clearProjectsEtagPoll = () => {
  eTagPoll = null;
};
export const stopProjectsPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};
export const restartProjectsPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};
export const forceProjectsRequest = () => {
  if (eTagPoll) eTagPoll.makeRequest();
};

export const addProjectsToDashboard = ({ state, dispatch }) => {
  axios
    .post(state.projectEndpoints.add, {
      project_ids: state.projectTokens.map(project => project.id),
    })
    .then(response => dispatch('requestAddProjectsToDashboardSuccess', response.data))
    .catch(() => dispatch('requestAddProjectsToDashboardError'));
};

export const clearInputValue = ({ commit }) => {
  commit(types.SET_INPUT_VALUE, '');
};

export const clearProjectTokens = ({ commit }) => {
  commit(types.SET_PROJECT_TOKENS, []);
};

export const filterProjectTokensById = ({ commit, state }, ids) => {
  const tokens = state.projectTokens.filter(token => ids.includes(token.id));
  commit(types.SET_PROJECT_TOKENS, tokens);
};

export const requestAddProjectsToDashboardSuccess = ({ dispatch, state }, data) => {
  const { added, invalid } = data;

  dispatch('clearInputValue');

  if (invalid.length) {
    const projectNames = state.projectTokens.reduce((accumulator, project) => {
      if (invalid.includes(project.id)) {
        accumulator.push(project.name);
      }
      return accumulator;
    }, []);
    let invalidProjects;
    if (projectNames.length > 2) {
      invalidProjects = `${projectNames.slice(0, -1).join(', ')}, and ${projectNames.pop()}`;
    } else if (projectNames.length > 1) {
      invalidProjects = projectNames.join(' and ');
    } else {
      [invalidProjects] = projectNames;
    }
    createFlash(
      sprintf(
        s__(
          'OperationsDashboard|Unable to add %{invalidProjects}. The Operations Dashboard is available for public projects, and private projects in groups with a Gold plan.',
        ),
        {
          invalidProjects,
        },
      ),
    );
    dispatch('filterProjectTokensById', invalid);
  } else {
    dispatch('clearProjectTokens');
  }

  if (added.length) {
    dispatch('fetchProjects');
  }
};

export const requestAddProjectsToDashboardError = ({ state }) => {
  createFlash(
    sprintf(__('Something went wrong, unable to add %{project} to dashboard'), {
      project: n__('project', 'projects', state.projectTokens.length),
    }),
  );
};

export const addProjectToken = ({ commit }, project) => {
  commit(types.ADD_PROJECT_TOKEN, project);
  commit(types.SET_INPUT_VALUE, '');
};

export const clearProjectSearchResults = ({ commit }) => {
  commit(types.SET_PROJECT_SEARCH_RESULTS, []);
};

export const fetchProjects = ({ state, dispatch }) => {
  if (eTagPoll) return;

  dispatch('requestProjects');

  eTagPoll = new Poll({
    resource: {
      fetchProjects: () => axios.get(state.projectEndpoints.list),
    },
    method: 'fetchProjects',
    successCallback: ({ data }) => dispatch('receiveProjectsSuccess', data),
    errorCallback: () => dispatch('receiveProjectsError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartProjectsPolling');
    } else {
      dispatch('stopProjectsPolling');
    }
  });
};

export const requestProjects = ({ commit }) => {
  commit(types.REQUEST_PROJECTS);
};

export const receiveProjectsSuccess = ({ commit }, data) => {
  commit(types.SET_PROJECTS, data.projects);
};

export const receiveProjectsError = ({ commit }) => {
  commit(types.SET_PROJECTS, null);
  createFlash(__('Something went wrong, unable to get operations projects'));
};

export const removeProject = ({ dispatch }, removePath) => {
  axios
    .delete(removePath)
    .then(() => dispatch('requestRemoveProjectSuccess'))
    .catch(() => dispatch('requestRemoveProjectError'));
};

export const requestRemoveProjectSuccess = ({ dispatch }) => {
  dispatch('forceProjectsRequest');
};

export const requestRemoveProjectError = () => {
  createFlash(__('Something went wrong, unable to remove project'));
};

export const removeProjectTokenAt = ({ commit }, index) => {
  commit(types.REMOVE_PROJECT_TOKEN_AT, index);
};

export const searchProjects = ({ commit }, query) => {
  commit(types.INCREMENT_PROJECT_SEARCH_COUNT, 1);

  Api.projects(query, {})
    .then(data => data)
    .catch(() => [])
    .then(results => {
      commit(types.SET_PROJECT_SEARCH_RESULTS, results);
      commit(types.DECREMENT_PROJECT_SEARCH_COUNT, 1);
    })
    .catch(() => {});
};

export const setInputValue = ({ commit }, value) => {
  commit(types.SET_INPUT_VALUE, value);
};

export const setProjectEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_PROJECT_ENDPOINT_LIST, endpoints.list);
  commit(types.SET_PROJECT_ENDPOINT_ADD, endpoints.add);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
