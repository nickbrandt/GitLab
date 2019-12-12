import Api from 'ee/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

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

  const { currentPage: page } = state;
  const query = { page };

  Api.getGeoDesigns(query)
    .then(res => {
      const normalizedHeaders = normalizeHeaders(res.headers);
      const paginationInformation = parseIntPagination(normalizedHeaders);

      dispatch('receiveDesignsSuccess', {
        data: res.data,
        perPage: paginationInformation.perPage,
        total: paginationInformation.total,
      });
    })
    .catch(() => {
      dispatch('receiveDesignsError');
    });
};

// Pagination
export const setPage = ({ commit }, page) => {
  commit(types.SET_PAGE, page);
};
