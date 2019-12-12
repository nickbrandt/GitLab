import * as types from './mutation_types';

export default {
  [types.SET_ENDPOINT](state, payload) {
    state.endpoint = payload;
  },
};
