import _ from 'underscore';
import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { GROUP_PAGE_TYPE } from '../constants';

export default {
  [types.SET_INITIAL_STATE](state, config) {
    state.config = {
      ...config,
      isGroupPage: config.pageType === GROUP_PAGE_TYPE,
      canDestroyPackage: !(
        _.isNull(config.canDestroyPackage) || _.isUndefined(config.canDestroyPackage)
      ),
    };
  },

  [types.SET_PACKAGE_LIST_SUCCESS](state, packages) {
    state.packages = packages;
  },

  [types.SET_MAIN_LOADING](state, isLoading) {
    state.isLoading = isLoading;
  },

  [types.SET_PAGINATION](state, headers) {
    const normalizedHeaders = normalizeHeaders(headers);
    state.pagination = parseIntPagination(normalizedHeaders);
  },
};
