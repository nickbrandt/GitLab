import * as types from './mutation_types';

export default {
  [types.SET_VISIBLE](state, isVisible) {
    Object.assign(state, {
      isVisible,
    });
  },
  [types.HIDE_SPLASH](state) {
    Object.assign(state, {
      isShowSplash: false,
    });
  },
  [types.SET_PATHS](state, paths) {
    Object.assign(state, {
      paths,
    });
  },
  [types.REQUEST_CHECK](state, type) {
    Object.assign(state.checks, {
      [type]: {
        isLoading: true,
      },
    });
  },
  [types.RECEIVE_CHECK_ERROR](state, { type, message }) {
    Object.assign(state.checks, {
      [type]: {
        isLoading: false,
        isValid: false,
        message,
      },
    });
  },
  [types.RECEIVE_CHECK_SUCCESS](state, type) {
    Object.assign(state.checks, {
      [type]: {
        isLoading: false,
        isValid: true,
        message: null,
      },
    });
  },
};
