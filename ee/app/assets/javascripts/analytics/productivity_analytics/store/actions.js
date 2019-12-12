import SET_ENDPOINT from './mutation_types';

// eslint-disable-next-line import/prefer-default-export
export const setEndpoint = ({ commit }, endpoint) => commit(SET_ENDPOINT, endpoint);
