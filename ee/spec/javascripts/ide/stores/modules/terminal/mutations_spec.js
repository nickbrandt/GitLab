import { CHECK_CONFIG, CHECK_RUNNERS } from 'ee/ide/constants';
import createState from 'ee/ide/stores/modules/terminal/state';
import * as types from 'ee/ide/stores/modules/terminal/mutation_types';
import mutations from 'ee/ide/stores/modules/terminal/mutations';

describe('EE IDE store terminal mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.SET_VISIBLE, () => {
    it('sets isVisible', () => {
      state.isVisible = false;

      mutations[types.SET_VISIBLE](state, true);

      expect(state.isVisible).toBe(true);
    });
  });

  describe(types.HIDE_SPLASH, () => {
    it('sets isShowSplash', () => {
      state.isShowSplash = true;

      mutations[types.HIDE_SPLASH](state);

      expect(state.isShowSplash).toBe(false);
    });
  });

  describe(types.SET_PATHS, () => {
    it('sets paths', () => {
      const paths = {
        test: 'foo',
      };

      mutations[types.SET_PATHS](state, paths);

      expect(state.paths).toBe(paths);
    });
  });

  describe(types.REQUEST_CHECK, () => {
    it('sets isLoading for check', () => {
      const type = CHECK_CONFIG;

      state.checks[type] = {};
      mutations[types.REQUEST_CHECK](state, type);

      expect(state.checks[type]).toEqual({
        isLoading: true,
      });
    });
  });

  describe(types.RECEIVE_CHECK_ERROR, () => {
    it('sets error for check', () => {
      const type = CHECK_RUNNERS;
      const message = 'lorem ipsum';

      state.checks[type] = {};
      mutations[types.RECEIVE_CHECK_ERROR](state, { type, message });

      expect(state.checks[type]).toEqual({
        isLoading: false,
        isValid: false,
        message,
      });
    });
  });

  describe(types.RECEIVE_CHECK_SUCCESS, () => {
    it('sets success for check', () => {
      const type = CHECK_CONFIG;

      state.checks[type] = {};
      mutations[types.RECEIVE_CHECK_SUCCESS](state, type);

      expect(state.checks[type]).toEqual({
        isLoading: false,
        isValid: true,
        message: null,
      });
    });
  });
});
