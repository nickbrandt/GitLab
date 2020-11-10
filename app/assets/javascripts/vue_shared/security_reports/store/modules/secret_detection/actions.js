import { fetchDiffData } from '../../utils';
import * as types from './mutation_types';

export const setSecretScanningDiffEndpoint = ({ commit }, path) =>
  commit(types.SET_SECRET_SCANNING_DIFF_ENDPOINT, path);

export const requestSecretScanningDiff = ({ commit }) => commit(types.REQUEST_SECRET_SCANNING_DIFF);

export const receiveSecretScanningDiffSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_SECRET_SCANNING_DIFF_SUCCESS, response);

export const receiveSecretScanningDiffError = ({ commit }, error) =>
  commit(types.RECEIVE_SECRET_SCANNING_DIFF_ERROR, error);

export const fetchSecretScanningDiff = ({ state, rootState, dispatch }) => {
  dispatch('requestSecretScanningDiff');

  return fetchDiffData(rootState, state.paths.diffEndpoint, 'secret_detection')
    .then(data => {
      dispatch('receiveSecretScanningDiffSuccess', data);
    })
    .catch(() => {
      dispatch('receiveSecretScanningDiffError');
    });
};
