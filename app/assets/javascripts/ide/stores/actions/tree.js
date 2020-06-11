import * as types from '../mutation_types';

export const toggleTreeOpen = ({ dispatch }, path) => {
  dispatch('fileSystem/toggleOpenTree', path);
};

export const showTreeEntry = ({ dispatch }, path) => {
  dispatch('fileSystem/openParents', path);
};

export const handleTreeEntryAction = ({ state, commit, dispatch }, path) => {
  const entry = state.fileSystem.files[path];

  if (!entry) {
    return;
  } else if (entry.type === 'tree') {
    // dispatch('toggleTreeOpen', path);
  } else if (entry.type === 'blob') {
    if (!entry.opened) {
      commit(types.TOGGLE_FILE_OPEN, path);
    }

    dispatch('setFileActive', path);
  }

  dispatch('showTreeEntry', path);
};

export const setDirectoryData = ({ state, commit }, { branchId, treeList }) => {
  const projectId = state.currentProjectId;
  const selectedTree = state.trees[`${projectId}/${branchId}`];

  commit(types.SET_DIRECTORY_DATA, {
    treePath: `${projectId}/${branchId}`,
    data: treeList,
  });
  commit(types.TOGGLE_LOADING, {
    entry: selectedTree,
    forceValue: false,
  });
};

export const getFiles = ({ state, dispatch }, payload = {}) => {
  const projectPath = state.project.path_with_namespace;
  const { branchId, ref = branchId } = payload;

  return dispatch('fileSystem/fetchFiles', { projectPath, ref });
};

export const restoreTree = ({ dispatch, commit, state }, path) => {
  const entry = state.entries[path];

  commit(types.RESTORE_TREE, path);

  if (entry.parentPath) {
    dispatch('restoreTree', entry.parentPath);
  }
};
