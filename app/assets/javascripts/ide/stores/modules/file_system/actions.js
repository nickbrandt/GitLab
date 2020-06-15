/* eslint-disable import/prefer-default-export */
import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';
import service from '../../../services';
import { parseToFileObjects } from './utils/parse';
import * as types from './mutation_types';

export const fetchFiles = ({ commit }, { projectPath, ref }) => {
  return service.getFiles(projectPath, ref).then(({ data }) => {
    commit(types.SET_FILES, parseToFileObjects(data));
  });
};

export const fetchFileData = ({ dispatch, state, rootState, rootGetters, commit }, path) => {
  const file = state.files[path];

  if (!file || file.isLoaded) return Promise.resolve();

  commit(types.SET_FILE_LOADING, { path, isLoading: true });

  const url = joinPaths(
    gon.relative_url_root || '/',
    rootState.currentProjectId,
    '-',
    file.type,
    rootGetters.lastCommit && rootGetters.lastCommit.id,
    escapeFileUrl(file.path),
  );

  return service
    .getAllFileData(url)
    .then(data => {
      commit(types.SET_FILE_DATA, { path, data });
      commit(types.SET_FILE_LOADING, { path, isLoading: false });
      // NOTE: There's probably a more decoupled way to handle this...
      return dispatch('git/loadBlob', { path, content: data.content }, { root: true });
    })
    .catch(() => {
      commit(types.SET_FILE_LOADING, { path, isLoading: false });
    });
};

export const toggleOpenTree = ({ commit }, path) => {
  commit(types.TOGGLE_OPEN_TREE, path);
};

export const openTree = ({ commit }, payload) => {
  commit(types.OPEN_TREE, payload);
};

export const openParents = ({ commit }, path) => {
  commit(types.OPEN_PARENTS, path);
};

export const setFileContent = ({ commit }, payload) => {
  commit(types.SET_FILE_CONTENT, payload);
};

export const removeFile = ({ commit }, path) => {
  commit(types.REMOVE_FILE, path);
};
