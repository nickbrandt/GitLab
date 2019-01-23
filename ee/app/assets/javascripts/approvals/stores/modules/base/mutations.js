import * as types from './mutation_types';

export default {
  [types.SET_LOADING](state, isLoading) {
    state.isLoading = isLoading;
  },
  [types.SET_APPROVAL_SETTINGS](state, settings) {
    state.hasLoaded = true;
    state.rules = settings.rules;
    state.fallbackApprovalsRequired = settings.fallbackApprovalsRequired;
  },
};
