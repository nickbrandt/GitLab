import axios from 'axios';
import actionsCE from '~/boards/stores/actions';
import boardsStoreEE from './boards_store_ee';
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
  updateListWipLimit({ state }, { maxIssueCount }) {
    const { activeListId } = state;

    return axios.put(`${boardsStoreEE.store.state.endpoints.listsEndpoint}/${activeListId}`, {
      list: {
        max_issue_count: maxIssueCount,
      },
    });
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
