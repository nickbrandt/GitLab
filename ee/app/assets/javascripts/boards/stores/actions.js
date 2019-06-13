import actionsCE from '~/boards/stores/actions';

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
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
