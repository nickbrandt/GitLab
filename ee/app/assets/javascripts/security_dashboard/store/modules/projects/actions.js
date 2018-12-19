import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export const setProjectsEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_PROJECTS_ENDPOINT, endpoint);
};

export const fetchProjects = ({ state, dispatch }) => {
  dispatch('requestProjects');

  axios({
    method: 'GET',
    url: state.projectsEndpoint,
  })
    .then(response => {
      const { data } = response;
      dispatch('receiveProjectsSuccess', { data });
    })
    .catch(() => {
      dispatch('receiveProjectsError');
    });
};

export const requestProjects = ({ commit }) => {
  commit(types.REQUEST_PROJECTS);
};

export const receiveProjectsSuccess = ({ commit }, { data }) => {
  const projects = data;

  commit(types.RECEIVE_PROJECTS_SUCCESS, { projects });
};

export const receiveProjectsError = ({ commit }) => {
  commit(types.RECEIVE_PROJECTS_ERROR);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
