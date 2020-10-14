import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import eventHub from '../../eventhub';
import service from '../../services';
import * as types from '../mutation_types';
import { setPageTitleForFile } from '../utils';

export const openFile = ({ commit, dispatch, state }, path) => {
  const isOpen = state.openFiles.find(f => f.path === path);

  if (!isOpen) commit(types.TOGGLE_FILE_OPEN, path);

  dispatch('setFileActive', path);
};

export const closeFile = ({ commit, state, dispatch, getters }, file) => {
  const { path } = file;
  const indexOfClosedFile = state.openFiles.findIndex(f => f.key === file.key);
  const fileWasActive = getters.isFileActive(file);

  commit(types.TOGGLE_FILE_OPEN, path);
  commit(types.SET_FILE_ACTIVE, { path, active: false });

  if (state.openFiles.length > 0 && fileWasActive) {
    const nextIndexToOpen = indexOfClosedFile === 0 ? 0 : indexOfClosedFile - 1;
    const nextFileToOpen = state.openFiles[nextIndexToOpen];

    dispatch('router/push', getters.getUrlForPath(nextFileToOpen.path), { root: true });
  } else if (!state.openFiles.length) {
    dispatch('router/push', `/project/${state.currentProjectId}/tree/${state.currentBranchId}/`, {
      root: true,
    });
  }

  eventHub.$emit(`editor.update.model.dispose.${file.key}`);
};

export const setFileActive = ({ commit, state, dispatch, getters }, path) => {
  const file = state.entries[path];
  const currentActiveFile = state.activeFile;

  if (getters.isFileActive(file)) return;

  if (currentActiveFile) {
    commit(types.SET_FILE_ACTIVE, {
      path: currentActiveFile.path,
      active: false,
    });
  }

  commit(types.SET_FILE_ACTIVE, { path, active: true });
  dispatch('scrollToTab');
};

export const getFileData = (
  { state, commit, dispatch, getters },
  { path, makeFileActive = true, openFile = makeFileActive, toggleLoading = true },
) => {
  const file = state.entries[path];

  if (file.raw || (file.tempFile && !file.prevPath)) return Promise.resolve();

  commit(types.TOGGLE_LOADING, { entry: file, forceValue: true });

  const url = joinPaths(
    gon.relative_url_root || '/',
    state.currentProjectId,
    '-',
    file.type,
    getters.lastCommit && getters.lastCommit.id,
    escapeFileUrl(file.prevPath || file.path),
  );

  return service
    .getFileData(url)
    .then(({ data }) => {
      if (data) commit(types.SET_FILE_DATA, { data, file });
      if (openFile) commit(types.TOGGLE_FILE_OPEN, path);

      if (makeFileActive) {
        setPageTitleForFile(state, file);
        dispatch('setFileActive', path);
      }
    })
    .catch(() => {
      dispatch('setErrorMessage', {
        text: __('An error occurred while loading the file.'),
        action: payload =>
          dispatch('getFileData', payload).then(() => dispatch('setErrorMessage', null)),
        actionText: __('Please try again'),
        actionPayload: { path, makeFileActive },
      });
    })
    .finally(() => {
      if (toggleLoading) commit(types.TOGGLE_LOADING, { entry: file, forceValue: false });
    });
};

export const setFileMrChange = ({ commit }, { file, mrChange }) => {
  commit(types.SET_FILE_MERGE_REQUEST_CHANGE, { file, mrChange });
};

export const getRawFileData = ({ state, commit, dispatch, getters }, { path }) => {
  const file = state.entries[path];

  commit(types.TOGGLE_LOADING, { entry: file, forceValue: true });
  return service
    .getRawFileData(file)
    .then(raw => {
      if (!(file.tempFile && !file.prevPath)) {
        commit(types.SET_FILE_RAW_DATA, { file, raw });
      }

      if (file.mrChange && file.mrChange.new_file === false) {
        const baseSha =
          (getters.currentMergeRequest && getters.currentMergeRequest.baseCommitSha) || '';

        return service.getBaseRawFileData(file, state.currentProjectId, baseSha).then(baseRaw => {
          commit(types.SET_FILE_BASE_RAW_DATA, {
            file,
            baseRaw,
          });
          return raw;
        });
      }
      return raw;
    })
    .catch(e => {
      dispatch('setErrorMessage', {
        text: __('An error occurred while loading the file content.'),
        action: payload =>
          dispatch('getRawFileData', payload).then(() => dispatch('setErrorMessage', null)),
        actionText: __('Please try again'),
        actionPayload: { path },
      });
      throw e;
    })
    .finally(() => {
      commit(types.TOGGLE_LOADING, { entry: file, forceValue: false });
    });
};

export const changeFileContent = ({ commit, state }, { path, content }) => {
  const file = state.entries[path];
  commit(types.UPDATE_FILE_CONTENT, {
    path,
    content,
  });

  const indexOfChangedFile = state.changedFiles.findIndex(f => f.path === path);

  if (file.changed && indexOfChangedFile === -1) {
    commit(types.ADD_FILE_TO_CHANGED, path);
  } else if (!file.changed && !file.tempFile && indexOfChangedFile !== -1) {
    commit(types.REMOVE_FILE_FROM_CHANGED, path);
  }
};

export const setFileLanguage = ({ state, commit }, { fileLanguage }) => {
  if (state.activeFile) {
    commit(types.SET_FILE_LANGUAGE, { file: state.activeFile, fileLanguage });
  }
};

export const setEditorPosition = ({ state, commit }, { editorRow, editorColumn }) => {
  if (state.activeFile) {
    commit(types.SET_FILE_POSITION, {
      file: state.activeFile,
      editorRow,
      editorColumn,
    });
  }
};

export const setFileViewMode = ({ commit }, { file, viewMode }) => {
  commit(types.SET_FILE_VIEWMODE, { file, viewMode });
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

  if (!isDestructiveDiscard && file.path === state.activeFile?.path) {
    dispatch('updateDelayViewerUpdated', true)
      .then(() => {
        dispatch('router/push', getters.getUrlForPath(file.path), { root: true });
      })
      .catch(e => {
        throw e;
      });
  }

  commit(types.REMOVE_FILE_FROM_CHANGED, path);

  eventHub.$emit(`editor.update.model.new.content.${file.key}`, file.content);
  eventHub.$emit(`editor.update.model.dispose.unstaged-${file.key}`, file.content);
};

export const triggerFilesChange = () => {
  // Used in EE for file mirroring
  eventHub.$emit('ide.files.change');
};
