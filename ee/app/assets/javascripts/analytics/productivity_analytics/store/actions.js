import SET_ENDPOINT from './mutation_types';

export const setEndpoint = ({ commit }, endpoint) => commit(SET_ENDPOINT, endpoint);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
