import * as types from './mutation_types';

export const setSelectedGroup = ({ commit }, group) => commit(types.SET_SELECTED_GROUP, group);
export const setSelectedProject = ({ commit }, project) =>
  commit(types.SET_SELECTED_PROJECT, project);
export const setSelectedFileQuantity = ({ commit }, fileQuantity) =>
  commit(types.SET_SELECTED_FILE_QUANTITY, fileQuantity);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
