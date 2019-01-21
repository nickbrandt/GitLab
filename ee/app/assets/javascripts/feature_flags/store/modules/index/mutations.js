import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

export default {
  [types.SET_FEATURE_FLAGS_ENDPOINT](state, endpoint) {
    state.endpoint = endpoint;
  },
  [types.SET_FEATURE_FLAGS_OPTIONS](state, options = {}) {
    state.options = options;
  },
  [types.REQUEST_FEATURE_FLAGS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_FEATURE_FLAGS_SUCCESS](state, response) {
    state.isLoading = false;
    state.hasError = false;
    state.featureFlags = response.data.feature_flags;
    state.count = response.data.count;

    let paginationInfo;
    if (Object.keys(response.headers).length) {
      const normalizedHeaders = normalizeHeaders(response.headers);
      paginationInfo = parseIntPagination(normalizedHeaders);
    } else {
      paginationInfo = response.headers;
    }
    state.pageInfo = paginationInfo;
  },
  [types.RECEIVE_FEATURE_FLAGS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
};
