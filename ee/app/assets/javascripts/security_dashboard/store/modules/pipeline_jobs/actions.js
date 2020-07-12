import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export const setPipelineJobsPath = ({ commit }, path) => commit(types.SET_PIPELINE_JOBS_PATH, path);

export const setProjectId = ({ commit }, id) => commit(types.SET_PROJECT_ID, id);

export const fetchPipelineJobs = ({ commit, state }) => {
  if (!state.pipelineJobsPath) {
    return commit(types.RECEIVE_PIPELINE_JOBS_ERROR, new Error('pipelineJobsPath not defined'));
  }
  commit(types.REQUEST_PIPELINE_JOBS);

  return axios({
    method: 'GET',
    url: state.pipelineJobsPath,
  })
    .then(response => {
      const { data } = response;
      commit(types.RECEIVE_PIPELINE_JOBS_SUCCESS, data);
    })
    .catch(error => {
      commit(types.RECEIVE_PIPELINE_JOBS_ERROR, error);
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
