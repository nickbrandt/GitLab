import * as types from './mutation_types';

export default {
  [types.SET_SELECTED_GROUP](state, group) {
    state.selectedGroup = group;
    state.selectedProject = null;
  },
  [types.SET_SELECTED_PROJECT](state, project) {
    state.selectedProject = project;
  },
  [types.SET_SELECTED_FILE_QUANTITY](state, fileQuantity) {
    state.selectedFileQuantity = fileQuantity;
  },
};
