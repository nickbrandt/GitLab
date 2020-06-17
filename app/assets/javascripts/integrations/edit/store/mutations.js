import * as types from './mutation_types';

export default {
  [types.SET_OVERRIDE](state, override) {
    state.override = override;
  },

  [types.SET_OVERRIDE_AVAILABLE](state, overrideAvailable) {
    state.overrideAvailable = overrideAvailable;
  },
};
