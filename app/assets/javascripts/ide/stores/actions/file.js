import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import eventHub from '../../eventhub';
import service from '../../services';
import * as types from '../mutation_types';
import { setPageTitleForFile } from '../utils';
import { viewerTypes, stageKeys } from '../../constants';

export const closeFile = ({ commit, state, dispatch }, file) => {
  const { path } = file;
  const indexOfClosedFile = state.openFiles.findIndex(f => f === path);
  const fileWasActive = path === state.activeFilePath;

  if (file.pending) {
    commit(types.REMOVE_PENDING_TAB, file);
  } else {
    commit(types.TOGGLE_FILE_OPEN, path);
    commit(types.SET_FILE_ACTIVE, { path, active: false });
  }

  if (state.openFiles.length > 0 && fileWasActive) {
    const nextIndexToOpen = indexOfClosedFile === 0 ? 0 : indexOfClosedFile - 1;
    const nextFileToOpen = state.openFiles[nextIndexToOpen];

    if (nextFileToOpen.pending) {
      dispatch('updateViewer', viewerTypes.diff);
      dispatch('openPendingTab', {
        file: nextFileToOpen,
        keyPrefix: nextFileToOpen.staged ? 'staged' : 'unstaged',
      });
    } else {
      dispatch('goToFileUrl', nextFileToOpen.path);
    }
  } else if (!state.openFiles.length) {
    dispatch('goToFileUrl');
  }

  eventHub.$emit(`editor.update.model.dispose.${file.path}`);
};

export const goToFileUrl = ({ state, dispatch }, path) => {
  const file = path && state.fileSystem.files[path];
  const type = file?.type || 'tree';

  const baseUrl = `/project/${state.currentProjectId}/${type}/${state.currentBranchId}/`;

  const url = file ? `${baseUrl}-/${file.path}${type === 'tree' ? '/' : ''}` : baseUrl;

  dispatch('router/push', url, { root: true });
};

export const setFileActive = ({ commit, dispatch }, path) => {
  commit(types.SET_FILE_ACTIVE, path);
  dispatch('scrollToTab');
};

export const getFileData = ({ dispatch }, { path }) => {
  return dispatch('fileSystem/fetchFileData', path);
};

export const setFileMrChange = ({ commit }, { file, mrChange }) => {
  commit(types.SET_FILE_MERGE_REQUEST_CHANGE, { file, mrChange });
};

export const getRawFileData = ({ state, commit, dispatch, getters }, { path }) => {
  const file = state.entries[path];
  const stagedFile = state.stagedFiles.find(f => f.path === path);

  return new Promise((resolve, reject) => {
    const fileDeletedAndReadded = getters.isFileDeletedAndReadded(path);
    service
      .getRawFileData(fileDeletedAndReadded ? stagedFile : file)
      .then(raw => {
        if (!(file.tempFile && !file.prevPath && !fileDeletedAndReadded))
          commit(types.SET_FILE_RAW_DATA, { file, raw, fileDeletedAndReadded });

        if (file.mrChange && file.mrChange.new_file === false) {
          const baseSha =
            (getters.currentMergeRequest && getters.currentMergeRequest.baseCommitSha) || '';

          service
            .getBaseRawFileData(file, baseSha)
            .then(baseRaw => {
              commit(types.SET_FILE_BASE_RAW_DATA, {
                file,
                baseRaw,
              });
              resolve(raw);
            })
            .catch(e => {
              reject(e);
            });
        } else {
          resolve(raw);
        }
      })
      .catch(() => {
        dispatch('setErrorMessage', {
          text: __('An error occurred while loading the file content.'),
          action: payload =>
            dispatch('getRawFileData', payload).then(() => dispatch('setErrorMessage', null)),
          actionText: __('Please try again'),
          actionPayload: { path },
        });
        reject();
      });
  });
};

export const changeFileContent = ({ dispatch }, payload) => {
  dispatch('fileSystem/setFileContent', payload);
};

export const restoreOriginalFile = ({ dispatch, state, commit }, path) => {
  const file = state.entries[path];
  const isDestructiveDiscard = file.tempFile || file.prevPath;

  if (file.deleted && file.parentPath) {
    dispatch('restoreTree', file.parentPath);
  }

  if (isDestructiveDiscard) {
    dispatch('closeFile', file);
  }

  if (file.tempFile) {
    dispatch('deleteEntry', file.path);
  } else {
    commit(types.DISCARD_FILE_CHANGES, file.path);
  }

  if (file.prevPath) {
    dispatch('renameEntry', {
      path: file.path,
      name: file.prevName,
      parentPath: file.prevParentPath,
    });
  }
};

export const discardFileChanges = ({ dispatch, state, commit, getters }, path) => {
  const file = state.entries[path];
  const isDestructiveDiscard = file.tempFile || file.prevPath;

  dispatch('restoreOriginalFile', path);

  if (!isDestructiveDiscard && file.path === getters.activeFile?.path) {
    dispatch('updateDelayViewerUpdated', true)
      .then(() => {
        dispatch('goToFileUrl', file.path);
      })
      .catch(e => {
        throw e;
      });
  }

  commit(types.REMOVE_FILE_FROM_CHANGED, path);

  eventHub.$emit(`editor.update.model.new.content.${file.path}`, file.content);
  eventHub.$emit(`editor.update.model.dispose.unstaged-${file.path}`, file.content);
};

export const stageChange = ({ state, commit, dispatch, getters }, path) => {
  const stagedFile = getters.getStagedFile(path);
  const openFile = getters.getOpenFile(path);

  commit(types.STAGE_CHANGE, { path, diffInfo: getters.getDiffInfo(path) });
  commit(types.SET_LAST_COMMIT_MSG, '');

  if (stagedFile) {
    eventHub.$emit(`editor.update.model.new.content.staged-${stagedFile.path}`, stagedFile.content);
  }

  const file = getters.getStagedFile(path);

  if (openFile && path === state.activeFilePath && file) {
    dispatch('openPendingTab', {
      file,
      keyPrefix: stageKeys.staged,
    });
  }
};

export const unstageChange = ({ state, commit, dispatch, getters }, path) => {
  const openFile = getters.getOpenFile(path);

  commit(types.UNSTAGE_CHANGE, { path, diffInfo: getters.getDiffInfo(path) });

  const file = getters.getChangedFile(path);

  if (openFile && path === state.activeFilePath && file) {
    dispatch('openPendingTab', {
      file,
      keyPrefix: stageKeys.unstaged,
    });
  }
};

export const openPendingTab = ({ commit, dispatch, getters, state }, { file, keyPrefix }) => {
  if (getters.activeFile && getters.activeFile.path === `${file.path}`) return false;

  state.openFiles.forEach(f => eventHub.$emit(`editor.update.model.dispose.${f}`));

  commit(types.ADD_PENDING_TAB, { file, keyPrefix });

  dispatch('router/push', `/project/${file.projectId}/tree/${state.currentBranchId}/`, {
    root: true,
  });

  return true;
};

export const removePendingTab = ({ commit }, file) => {
  commit(types.REMOVE_PENDING_TAB, file);

  eventHub.$emit(`editor.update.model.dispose.${file.key}`);
};

export const triggerFilesChange = () => {
  // Used in EE for file mirroring
  eventHub.$emit('ide.files.change');
};
