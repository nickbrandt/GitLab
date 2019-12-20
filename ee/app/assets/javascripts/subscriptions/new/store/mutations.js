import * as types from './mutation_types';

export default {
  [types.ACTIVATE_STEP](state, step) {
    state.currentStep = step;
  },
};
