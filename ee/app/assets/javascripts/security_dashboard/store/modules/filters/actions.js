import * as types from './mutation_types';

export const setFilter = ({ commit }, payload) => {
  commit(types.SET_FILTER, payload);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
