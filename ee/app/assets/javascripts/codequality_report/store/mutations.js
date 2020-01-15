import * as types from './mutation_types';

export default {
  [types.SET_ENDPOINT](state, endpoint) {
    Object.assign(state, { endpoint });
  },
  [types.SET_BLOB_PATH](state, blobPath) {
    Object.assign(state, { blobPath });
  },
  [types.REQUEST_REPORT](state) {
    Object.assign(state, { isLoadingCodequality: true });
  },
  [types.RECEIVE_REPORT_SUCCESS](state, issues) {
    Object.assign(state, {
      isLoadingCodequality: false,
      codeQualityIssues: issues,
    });
  },
  [types.RECEIVE_REPORT_ERROR](state, error) {
    Object.assign(state, {
      isLoadingCodequality: false,
      loadingCodequalityFailed: true,
      codeQualityError: error,
    });
  },
};
