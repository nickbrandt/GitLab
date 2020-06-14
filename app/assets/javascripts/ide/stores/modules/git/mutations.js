import { updateObjects } from './utils/fs';
import * as types from './mutation_types';

export default {
  [types.UPDATE_OBJECTS](state, { fs }) {
    const timestamp = state.lastTimestamp;

    const newRef = updateObjects({ objects: state.objects, fs, timestamp });

    state.refs.fs = newRef;
    if (timestamp < 0) {
      state.refs.head = newRef;
    }
  },
  [types.SAVE_LAST_TIMESTAMP](state, timestamp) {
    state.lastTimestamp = timestamp;
  },
};
