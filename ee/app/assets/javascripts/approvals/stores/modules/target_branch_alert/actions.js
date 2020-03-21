import * as types from './mutations_types';

export const displayTargetBranchAlert = ({ commit }, isShown) =>
  commit(types.TOGGLE_DISPLAY_TARGET_BRANCH_ALERT, isShown);

export const toggleDisplayTargetBranchAlert = ({ dispatch }, isShown) => {
  dispatch('displayTargetBranchAlert', isShown);
};

export const selectTargetBranch = ({ commit }, targetBranch) =>
  commit(types.SET_TARGET_BRANCH, targetBranch);

export const setTargetBranch = ({ dispatch }, targetBranch) => {
  dispatch('selectTargetBranch', targetBranch);
};

export default () => {};
