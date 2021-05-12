import * as types from 'ee/status_checks/store/mutation_types';
import mutations from 'ee/status_checks/store/mutations';
import initialState from 'ee/status_checks/store/state';

describe('Status checks mutations', () => {
  let state;

  beforeEach(() => {
    state = initialState();
  });

  describe(types.SET_LOADING, () => {
    it('sets isLoading', () => {
      expect(state.isLoading).toBe(false);

      mutations[types.SET_LOADING](state, true);

      expect(state.isLoading).toBe(true);
    });
  });

  describe(types.SET_SETTINGS, () => {
    it('sets the settings', () => {
      const settings = { projectId: '12345', statusChecksPath: 'foo/bar/baz' };

      expect(state.settings).toStrictEqual({});

      mutations[types.SET_SETTINGS](state, settings);

      expect(state.settings).toStrictEqual(settings);
    });
  });

  describe(types.SET_STATUS_CHECKS, () => {
    it('sets the statusChecks', () => {
      const statusChecks = [{ name: 'Foo' }, { name: 'Bar' }];

      expect(state.statusChecks).toStrictEqual([]);

      mutations[types.SET_STATUS_CHECKS](state, statusChecks);

      expect(state.statusChecks).toStrictEqual(statusChecks);
    });
  });
});
