import * as types from './mutation_types';

// eslint-disable-next-line import/prefer-default-export
export const setEndpoint = ({ commit }, endpoint) => commit(types.SET_ENDPOINT, endpoint);
