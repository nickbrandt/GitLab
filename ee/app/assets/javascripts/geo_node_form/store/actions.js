import Api from '~/api';
import ApiEE from 'ee/api';
import createFlash from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
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

export const requestSaveGeoNode = ({ commit }) => commit(types.REQUEST_SAVE_GEO_NODE);
export const receiveSaveGeoNodeSuccess = ({ commit }) => {
  commit(types.RECEIVE_SAVE_GEO_NODE_COMPLETE);
  visitUrl('/admin/geo/nodes');
};
export const receiveSaveGeoNodeError = ({ commit }) => {
  createFlash(__(`There was an error saving this Geo Node`));
  commit(types.RECEIVE_SAVE_GEO_NODE_COMPLETE);
};

export const saveGeoNode = ({ dispatch }, node) => {
  dispatch('requestSaveGeoNode');
  const sanitizedNode = convertObjectPropsToSnakeCase(node);
  const saveFunc = node.id ? 'updateGeoNode' : 'createGeoNode';

  ApiEE[saveFunc](sanitizedNode)
    .then(() => dispatch('receiveSaveGeoNodeSuccess'))
    .catch(() => {
      dispatch('receiveSaveGeoNodeError');
    });
};
