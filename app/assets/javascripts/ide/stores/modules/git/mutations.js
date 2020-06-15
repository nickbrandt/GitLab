import { updateObjects } from './utils/fs';
import * as types from './mutation_types';

const addAllRefsToSet = (objects, ref, keys) => {
  if (keys.has(ref)) {
    return;
  }

  keys.add(ref);
  const obj = objects[ref];

  if (!obj || obj.type === 'blob') {
    return;
  }

  obj.data.children.forEach(({ key }) => {
    addAllRefsToSet(objects, key, keys);
  });
};

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
  [types.SET_CLEANING_FLAG](state, val) {
    state.isCleaning = val;
  },
  [types.CLEAN_OBJECTS](state) {
    const keys = new Set();
    Object.values(state.refs).forEach(ref => {
      addAllRefsToSet(state.objects, ref, keys);
    });

    const toDelete = Object.keys(state.objects).filter(key => !keys.has(key));

    toDelete.forEach(key => {
      delete state.objects[key];
    });
  },
};
