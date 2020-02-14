import axios from '~/lib/utils/axios_utils';
import pollUntilComplete from '~/lib/utils/poll_until_complete';
import * as types from './mutation_types';

export const setDiffEndpoint = ({ commit }, path) => commit(types.SET_DIFF_ENDPOINT, path);

export const requestDiff = ({ commit }) => commit(types.REQUEST_DIFF);

export const updateVulnerability = ({ commit }, vulnerability) =>
  commit(types.UPDATE_VULNERABILITY, vulnerability);

export const receiveDiffSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_DIFF_SUCCESS, response);

export const receiveDiffError = ({ commit }, response) =>
  commit(types.RECEIVE_DIFF_ERROR, response);

export const fetchDiff = ({ state, rootState, dispatch }) => {
  dispatch('requestDiff');

  return Promise.all([
    pollUntilComplete(state.paths.diffEndpoint),
    axios.get(rootState.vulnerabilityFeedbackPath, {
      params: {
        category: 'sast',
      },
    }),
  ])
    .then(values => {
      dispatch('receiveDiffSuccess', {
        diff: values[0].data,
        enrichData: values[1].data,
      });
    })
    .catch(() => {
      dispatch('receiveDiffError');
    });
};

export default () => {};
