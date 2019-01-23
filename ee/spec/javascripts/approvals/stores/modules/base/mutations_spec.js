import createState from 'ee/approvals/stores/state';
import * as types from 'ee/approvals/stores/modules/base/mutation_types';
import mutations from 'ee/approvals/stores/modules/base/mutations';

describe('EE approvals base module mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.SET_LOADING, () => {
    it('sets isLoading', () => {
      state.isLoading = false;

      mutations[types.SET_LOADING](state, true);

      expect(state.isLoading).toBe(true);
    });
  });

  describe(types.SET_RULES, () => {
    it('sets rules', () => {
      const newRules = [{ id: 1 }, { id: 2 }];

      state.rules = [];

      mutations[types.SET_RULES](state, newRules);

      expect(state.rules).toEqual(newRules);
    });
  });
});
