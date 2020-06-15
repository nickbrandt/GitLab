import Api from 'ee/api';
import createFlash from '~/flash';
import toast from '~/vue_shared/plugins/global_toast';
import { __, sprintf } from '~/locale';
import {
  parseIntPagination,
  normalizeHeaders,
  convertObjectPropsToCamelCase,
} from '~/lib/utils/common_utils';
import packageFilesQuery from '../graphql/package_files.query.graphql';
import { gqClient } from '../utils';
import * as types from './mutation_types';
import { FILTER_STATES, PREV, NEXT } from '../constants';

// Fetch Replicable Items
export const requestReplicableItems = ({ commit }) => commit(types.REQUEST_REPLICABLE_ITEMS);
export const receiveReplicableItemsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_REPLICABLE_ITEMS_SUCCESS, data);
export const receiveReplicableItemsError = ({ state, commit }) => {
  createFlash(
    sprintf(__('There was an error fetching the %{replicableType}'), {
      replicableType: state.replicableType,
    }),
  );
  commit(types.RECEIVE_REPLICABLE_ITEMS_ERROR);
};

export const fetchReplicableItems = ({ state, dispatch }, direction) => {
  dispatch('requestReplicableItems');

  return state.useGraphQl
    ? dispatch('fetchReplicableItemsGraphQl', direction)
    : dispatch('fetchReplicableItemsRestful');
};

export const fetchReplicableItemsGraphQl = ({ state, dispatch }, direction) => {
  let before = '';
  let after = '';

  if (direction === PREV) {
    before = state.paginationData.startCursor;
  } else if (direction === NEXT) {
    after = state.paginationData.endCursor;
  }

  gqClient
    .query({
      query: packageFilesQuery,
      variables: { before, after },
    })
    .then(res => {
      const registries = res.data.geoNode.packageFileRegistries;
      const data = registries.edges.map(e => e.node);
      const pagination = registries.pageInfo;

      dispatch('receiveReplicableItemsSuccess', { data, pagination });
    })
    .catch(() => {
      dispatch('receiveReplicableItemsError');
    });
};

export const fetchReplicableItemsRestful = ({ state, dispatch }) => {
  const { filterOptions, currentFilterIndex, searchFilter, paginationData } = state;

  const statusFilter = currentFilterIndex ? filterOptions[currentFilterIndex] : filterOptions[0];

  const query = {
    page: paginationData.page,
    search: searchFilter || null,
    sync_status: statusFilter.value === FILTER_STATES.ALL.value ? null : statusFilter.value,
  };

  Api.getGeoReplicableItems(state.replicableType, query)
    .then(res => {
      const normalizedHeaders = normalizeHeaders(res.headers);
      const pagination = parseIntPagination(normalizedHeaders);
      const data = convertObjectPropsToCamelCase(res.data, { deep: true });

      dispatch('receiveReplicableItemsSuccess', { data, pagination });
    })
    .catch(() => {
      dispatch('receiveReplicableItemsError');
    });
};

// Initiate All Replicable Syncs
export const requestInitiateAllReplicableSyncs = ({ commit }) =>
  commit(types.REQUEST_INITIATE_ALL_REPLICABLE_SYNCS);
export const receiveInitiateAllReplicableSyncsSuccess = (
  { state, commit, dispatch },
  { action },
) => {
  toast(
    sprintf(__('All %{replicableType} are being scheduled for %{action}'), {
      replicableType: state.replicableType,
      action,
    }),
  );
  commit(types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_SUCCESS);
  dispatch('fetchReplicableItems');
};
export const receiveInitiateAllReplicableSyncsError = ({ state, commit }) => {
  createFlash(
    sprintf(__('There was an error syncing the %{replicableType}'), {
      replicableType: state.replicableType,
    }),
  );
  commit(types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_ERROR);
};

export const initiateAllReplicableSyncs = ({ state, dispatch }, action) => {
  dispatch('requestInitiateAllReplicableSyncs');

  Api.initiateAllGeoReplicableSyncs(state.replicableType, action)
    .then(() => dispatch('receiveInitiateAllReplicableSyncsSuccess', { action }))
    .catch(() => {
      dispatch('receiveInitiateAllReplicableSyncsError');
    });
};

// Initiate Replicable Sync
export const requestInitiateReplicableSync = ({ commit }) =>
  commit(types.REQUEST_INITIATE_REPLICABLE_SYNC);
export const receiveInitiateReplicableSyncSuccess = ({ commit, dispatch }, { name, action }) => {
  toast(sprintf(__('%{name} is scheduled for %{action}'), { name, action }));
  commit(types.RECEIVE_INITIATE_REPLICABLE_SYNC_SUCCESS);
  dispatch('fetchReplicableItems');
};
export const receiveInitiateReplicableSyncError = ({ commit }, { name }) => {
  createFlash(sprintf(__('There was an error syncing project %{name}'), { name }));
  commit(types.RECEIVE_INITIATE_REPLICABLE_SYNC_ERROR);
};

export const initiateReplicableSync = ({ state, dispatch }, { projectId, name, action }) => {
  dispatch('requestInitiateReplicableSync');

  Api.initiateGeoReplicableSync(state.replicableType, { projectId, action })
    .then(() => dispatch('receiveInitiateReplicableSyncSuccess', { name, action }))
    .catch(() => {
      dispatch('receiveInitiateReplicableSyncError', { name });
    });
};

// Filtering/Pagination
export const setFilter = ({ commit }, filterIndex) => {
  commit(types.SET_FILTER, filterIndex);
};

export const setSearch = ({ commit }, search) => {
  commit(types.SET_SEARCH, search);
};

export const setPage = ({ commit }, page) => {
  commit(types.SET_PAGE, page);
};
