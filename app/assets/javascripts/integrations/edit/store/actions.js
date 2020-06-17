import * as types from './mutation_types';

export const setOverride = ({ commit }, override) => commit(types.SET_OVERRIDE, override);

export const setOverrideAvailable = ({ commit }, overrideAvailable) =>
  commit(types.SET_OVERRIDE_AVAILABLE, overrideAvailable);
