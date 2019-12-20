import Vue from 'vue';
import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { mapToScopesViewModel } from '../helpers';

const mapFlag = flag => ({ ...flag, scopes: mapToScopesViewModel(flag.scopes || []) });

const updateFlag = (state, flag) => {
  const i = state.featureFlags.findIndex(({ id }) => id === flag.id);
  Vue.set(state.featureFlags, i, flag);

  Vue.set(state.count, 'enabled', state.featureFlags.filter(({ active }) => active).length);
  Vue.set(state.count, 'disabled', state.featureFlags.filter(({ active }) => !active).length);
};

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
    state.count = response.data.count;
    state.featureFlags = (response.data.feature_flags || []).map(mapFlag);

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
  [types.UPDATE_FEATURE_FLAG](state, flag) {
    updateFlag(state, mapFlag(flag));
  },
  [types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS](state, data) {
    updateFlag(state, mapFlag(data));
  },
  [types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR](state, i) {
    const flag = state.featureFlags.find(({ id }) => i === id);
    updateFlag(state, { ...flag, active: !flag.active });
  },
};
