import * as types from './mutation_types';

export const setInitialData = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
