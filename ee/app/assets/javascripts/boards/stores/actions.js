import actionsCE from '~/boards/stores/actions';
import * as types from './mutation_types';

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
  throw new Error('Not implemented!');
};

export default {
  ...actionsCE,

  toggleShowLabels({ commit }) {
    commit(types.TOGGLE_LABELS);
  },

  setActiveListId({ commit }, listId) {
    commit(types.SET_ACTIVE_LIST_ID, listId);
  },

  fetchAllBoards: () => {
    notImplemented();
  },

  fetchRecentBoards: () => {
    notImplemented();
  },

  createBoard: () => {
    notImplemented();
  },

  deleteBoard: () => {
    notImplemented();
  },

  updateIssueWeight: () => {
    notImplemented();
  },

  togglePromotionState: () => {
    notImplemented();
  },
};
