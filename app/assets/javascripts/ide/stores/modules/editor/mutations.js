import Vue from 'vue';
import * as types from './mutation_types';
import { getFileEditorOrDefault } from './utils';

export default {
  [types.UPDATE_FILE_EDITOR](state, { path, data }) {
    const editor = getFileEditorOrDefault(state.fileEditors, path);

    Vue.set(state.fileEditors, path, Object.assign(editor, data));
  },
  [types.REMOVE_FILE_EDITOR](state, path) {
    Vue.delete(state.fileEditors, path);
  },
};
