/* eslint-disable import/prefer-default-export */
import service from '../../../services';
import { parseToFileObjects } from './utils/parse';
import * as types from './mutation_types';

export const fetchFiles = ({ commit }, { projectPath, ref }) => {
  return service.getFiles(projectPath, ref).then(({ data }) => {
    commit(types.SET_FILES, parseToFileObjects(data));
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
