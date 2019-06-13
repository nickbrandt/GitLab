import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

export default {
  [types.SET_FEATURE_FLAGS_ENDPOINT](state, endpoint) {
    state.endpoint = endpoint;
  },
  [types.SET_FEATURE_FLAGS_OPTIONS](state, options = {}) {
    state.options = options;
  },
  [types.SET_INSTANCE_ID_ENDPOINT](state, endpoint) {
    state.rotateEndpoint = endpoint;
  },
  [types.SET_INSTANCE_ID](state, instance) {
    state.instanceId = instance;
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
  [types.REQUEST_ROTATE_INSTANCE_ID](state) {
    state.isRotating = true;
    state.hasRotateError = false;
  },
  [types.RECEIVE_ROTATE_INSTANCE_ID_SUCCESS](
    state,
    {
      data: { token },
    },
  ) {
    state.isRotating = false;
    state.instanceId = token;
    state.hasRotateError = false;
  },
  [types.RECEIVE_ROTATE_INSTANCE_ID_ERROR](state) {
    state.isRotating = false;
    state.hasRotateError = true;
  },
};
