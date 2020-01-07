import Api from 'ee/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import {
  parseIntPagination,
  normalizeHeaders,
  convertObjectPropsToCamelCase,
} from '~/lib/utils/common_utils';
import * as types from './mutation_types';
import { FILTER_STATES } from './constants';

// Fetch Designs
export const requestDesigns = ({ commit }) => commit(types.REQUEST_DESIGNS);
export const receiveDesignsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_DESIGNS_SUCCESS, data);
export const receiveDesignsError = ({ commit }) => {
  createFlash(__('There was an error fetching the Designs'));
  commit(types.RECEIVE_DESIGNS_ERROR);
};

export const fetchDesigns = ({ state, dispatch }) => {
  dispatch('requestDesigns');

  const statusFilterName = state.filterOptions[state.currentFilterIndex]
    ? state.filterOptions[state.currentFilterIndex]
    : state.filterOptions[0];
  const query = {
    page: state.currentPage,
    search: state.searchFilter ? state.searchFilter : null,
    sync_status: statusFilterName === FILTER_STATES.ALL ? null : statusFilterName,
  };

  Api.getGeoDesigns(query)
    .then(res => {
      const normalizedHeaders = normalizeHeaders(res.headers);
      const paginationInformation = parseIntPagination(normalizedHeaders);
      const camelCaseData = convertObjectPropsToCamelCase(res.data, { deep: true });

      dispatch('receiveDesignsSuccess', {
        data: camelCaseData,
        perPage: paginationInformation.perPage,
        total: paginationInformation.total,
      });
    })
    .catch(() => {
      dispatch('receiveDesignsError');
    });
};

// Initiate All Design Syncs
export const requestInitiateAllDesignSyncs = ({ commit }) =>
  commit(types.REQUEST_INITIATE_ALL_DESIGN_SYNCS);
export const receiveInitiateAllDesignSyncsSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_INITIATE_ALL_DESIGN_SYNCS_SUCCESS);
  dispatch('fetchDesigns');
};
export const receiveInitiateAllDesignSyncsError = ({ commit }) => {
  createFlash(__(`There was an error syncing the Design Repositories.`));
  commit(types.RECEIVE_INITIATE_ALL_DESIGN_SYNCS_ERROR);
};

export const initiateAllDesignSyncs = ({ dispatch }, action) => {
  dispatch('requestInitiateAllDesignSyncs');

  Api.initiateAllGeoDesignSyncs(action)
    .then(() => dispatch('receiveInitiateAllDesignSyncsSuccess'))
    .catch(() => {
      dispatch('receiveInitiateAllDesignSyncsError');
    });
};

// Initiate Design Sync
export const requestInitiateDesignSync = ({ commit }) => commit(types.REQUEST_INITIATE_DESIGN_SYNC);
export const receiveInitiateDesignSyncSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_INITIATE_DESIGN_SYNC_SUCCESS);
  dispatch('fetchDesigns');
};
export const receiveInitiateDesignSyncError = ({ commit }, { name }) => {
  createFlash(__(`There was an error syncing project '${name}'`));
  commit(types.RECEIVE_INITIATE_DESIGN_SYNC_ERROR);
};

export const initiateDesignSync = ({ dispatch }, { projectId, name, action }) => {
  dispatch('requestInitiateDesignSync');

  Api.initiateGeoDesignSync({ projectId, action })
    .then(() => dispatch('receiveInitiateDesignSyncSuccess'))
    .catch(() => {
      dispatch('receiveInitiateDesignSyncError', { name });
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
