import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

export default {
  [types.SET_PROJECT_ID](state, projectId) {
    state.projectId = projectId;
  },

  [types.SET_USER_CAN_DELETE](state, userCanDelete) {
    state.userCanDelete = userCanDelete;
  },

  [types.SET_PACKAGE_LIST](state, packages) {
    state.packages = packages;
  },

  [types.SET_MAIN_LOADING](state, isLoading) {
    state.isLoading = isLoading;
  },

  [types.SET_PAGINATION](state, { headers }) {
    const normalizedHeaders = normalizeHeaders(headers);
    state.pagination = parseIntPagination(normalizedHeaders);
  },
};
