/* eslint-disable no-param-reassign */
import * as types from './mutation_types';
import { getParentPaths } from './utils/path';

const updateEntry = (state, path, fn) => {
  const entry = state.files[path];

  if (!entry) {
    return;
  }

  fn(entry);
};
const setOpened = val => entry => {
  entry.opened = val;
};
const toggleOpened = entry => {
  entry.opened = !entry.opened;
};
const setOpenedTrue = setOpened(true);

export default {
  [types.SET_FILES](state, files) {
    Object.assign(state, { files });
  },
  [types.OPEN_PARENTS](state, path) {
    getParentPaths(path).forEach(parentPath => {
      updateEntry(state, parentPath, setOpenedTrue);
    });
  },
  [types.OPEN_TREE](state, { path, value }) {
    updateEntry(state, path, setOpened(value));
  },
  [types.TOGGLE_OPEN_TREE](state, path) {
    updateEntry(state, path, toggleOpened);
  },
};
