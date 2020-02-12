import * as types from './mutation_types';

export default {
  [types.REQUEST_SYNC_NAMESPACES](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_SYNC_NAMESPACES_SUCCESS](state, data) {
    state.isLoading = false;
    state.synchronizationNamespaces = data;
  },
  [types.RECEIVE_SYNC_NAMESPACES_ERROR](state) {
    state.isLoading = false;
    state.synchronizationNamespaces = [];
  },
};
