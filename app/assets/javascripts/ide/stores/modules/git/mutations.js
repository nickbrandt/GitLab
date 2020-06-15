import { updateObjects } from './utils/fs';
import * as types from './mutation_types';

export default {
  [types.UPDATE_OBJECTS](state, { fs }) {
    const { lastTimestamp, objects, refs } = state;

    const newRef = updateObjects({ objects, lastTimestamp, rootRef: refs.fs, fs });

    state.refs.fs = newRef;
    if (lastTimestamp < 0) {
      state.refs.head = newRef;
    }
  },
  [types.SAVE_LAST_TIMESTAMP](state, timestamp) {
    state.lastTimestamp = timestamp;
  },
};
