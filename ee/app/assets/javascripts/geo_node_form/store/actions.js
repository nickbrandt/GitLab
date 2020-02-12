import Api from '~/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const requestSyncNamespaces = ({ commit }) => commit(types.REQUEST_SYNC_NAMESPACES);
export const receiveSyncNamespacesSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_SYNC_NAMESPACES_SUCCESS, data);
export const receiveSyncNamespacesError = ({ commit }) => {
  createFlash(__("There was an error fetching the Node's Groups"));
  commit(types.RECEIVE_SYNC_NAMESPACES_ERROR);
};

export const fetchSyncNamespaces = ({ dispatch }, search) => {
  dispatch('requestSyncNamespaces');

  Api.groups(search)
    .then(res => {
      dispatch('receiveSyncNamespacesSuccess', res);
    })
    .catch(() => {
      dispatch('receiveSyncNamespacesError');
    });
};
