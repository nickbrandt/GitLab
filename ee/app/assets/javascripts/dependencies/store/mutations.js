import * as types from './mutation_types';

export default {
  [types.ADD_LIST_TYPE](state, payload) {
    state.listTypes.push(payload);
  },
  [types.SET_CURRENT_LIST](state, payload) {
    state.currentList = payload;
  },
};
