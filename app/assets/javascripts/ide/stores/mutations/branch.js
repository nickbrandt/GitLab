import * as types from '../mutation_types';

export default {
  [types.SET_CURRENT_BRANCH](state, currentBranchId) {
    Object.assign(state, {
      currentBranchId,
    });
  },
  [types.SET_BRANCH](state, { branchName, branch }) {
    const projectPath = state.currentProjectId;

    Object.assign(state.project, {
      branches: {
        [branchName]: {
          ...branch,
          treeId: `${projectPath}/${branchName}`,
          active: true,
          workingReference: '',
        },
      },
    });
  },
  [types.SET_BRANCH_WORKING_REFERENCE](state, { branchId, reference }) {
    if (!state.project.branches[branchId]) {
      Object.assign(state.project.branches, {
        [branchId]: {},
      });
    }

    Object.assign(state.project.branches[branchId], {
      workingReference: reference,
    });
  },
  [types.SET_BRANCH_COMMIT](state, { branchId, commit }) {
    Object.assign(state.project.branches[branchId], {
      commit,
    });
  },
};
