import Vue from 'vue';
import * as types from './mutation_types';

export default {
  [types.SET_FILE_INFO](state, { path, data }) {
    Vue.set(state.fileInfos, path, {
      ...(state.fileInfos[path] || {}),
      ...data,
    });
  },
};
