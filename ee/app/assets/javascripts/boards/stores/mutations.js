import * as mutationTypes from './mutation_types';

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
  throw new Error('Not implemented!');
};

export default {
  [mutationTypes.TOGGLE_LABELS]: state => {
    state.isShowingLabels = !state.isShowingLabels;
  },
  [mutationTypes.SET_ACTIVE_LIST_ID]: (state, id) => {
    state.activeListId = id;
  },

  [mutationTypes.REQUEST_AVAILABLE_BOARDS]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_AVAILABLE_BOARDS_SUCCESS]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_AVAILABLE_BOARDS_ERROR]: () => {
    notImplemented();
  },

  [mutationTypes.REQUEST_RECENT_BOARDS]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_RECENT_BOARDS_SUCCESS]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_RECENT_BOARDS_ERROR]: () => {
    notImplemented();
  },

  [mutationTypes.REQUEST_ADD_BOARD]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_ADD_BOARD_SUCCESS]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_ADD_BOARD_ERROR]: () => {
    notImplemented();
  },

  [mutationTypes.REQUEST_REMOVE_BOARD]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_REMOVE_BOARD_SUCCESS]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_REMOVE_BOARD_ERROR]: () => {
    notImplemented();
  },

  [mutationTypes.TOGGLE_PROMOTION_STATE]: () => {
    notImplemented();
  },
};
