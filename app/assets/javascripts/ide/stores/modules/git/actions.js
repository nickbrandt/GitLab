/* eslint-disable import/prefer-default-export */
import * as types from './mutation_types';

export const updateObjects = ({ state, commit, rootState }, timestamp) => {
  if (state.lastTimestamp === timestamp) {
    return;
  }

  commit(types.UPDATE_OBJECTS, { timestamp, fs: rootState.fileSystem.files });
  commit(types.SAVE_LAST_TIMESTAMP, timestamp);
};

export const cleanObjects = ({ commit }) => {
  commit(types.SET_CLEANING_FLAG, true);
  commit(types.CLEAN_OBJECTS);
  commit(types.SET_CLEANING_FLAG, false);
};
