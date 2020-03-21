import * as types from './mutations_types';

export default {
  [types.TOGGLE_DISPLAY_TARGET_BRANCH_ALERT](state, isShow) {
    state.showTargetBranchAlert = isShow;
  },
  [types.SET_TARGET_BRANCH](state, targetBranch) {
    state.targetBranch = targetBranch;
  },
};
