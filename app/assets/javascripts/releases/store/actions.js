import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { __ } from '~/locale';

/**
 * Commits a mutation to store the main endpoint.
 *
 * @param {String} endpoint
 */
export const setEndpoint = ({ commit }, endpoint) => commit(types.SET_ENDPOINT, endpoint);

/**
 * Commits a mutation to update the state while the main endpoint is being requested.
 */
export const requestReleases = ({ commit }) => commit(types.REQUEST_RELEASES);

/**
 * Fetches the main endpoint.
 * Will dispatch requestNamespace action before starting the request.
 * Will dispatch receiveNamespaceSuccess if the request is successfull
 * Will dispatch receiveNamesapceError if the request returns an error
 */
export const fetchReleases = ({ state, dispatch }) => {
  dispatch('requestReleases');

  axios
    .get(state.endpoint)
    .then(({ data }) => dispatch('receiveReleasesSuccess', data))
    .catch(() => dispatch('receiveReleasesError'));
};

export const receiveReleasesSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_RELEASES_SUCCESS, data);

export const receiveReleasesError = ({ commit }) => {
  commit(types.RECEIVE_RELEASES_ERROR);
  createFlash(__('An error occured while fetching the releases. Please try again.'));
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
