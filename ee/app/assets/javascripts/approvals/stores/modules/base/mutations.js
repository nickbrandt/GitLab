import * as types from './mutation_types';

export default {
  [types.SET_LOADING](state, isLoading) {
    state.isLoading = isLoading;
  },
  [types.SET_RULES](state, rules) {
    state.rules = rules;
  },
};
