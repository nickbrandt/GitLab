import actionsCE from '~/boards/stores/actions';

const notImplemented = () => {
  throw new Error('Not implemented!');
};

export default {
  ...actionsCE,

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
