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
    // Disabling for now since there's a collision between this being called and `ide_tree_list` calling `toggleTreeOpen`
    // dispatch('toggleTreeOpen', path);
  } else if (entry.type === 'blob') {
    if (!state.openFiles.some(x => x === entry.path)) {
      commit(types.TOGGLE_FILE_OPEN, path);
    }

    dispatch('setFileActive', path);
  }

  dispatch('showTreeEntry', path);
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
