import createState from 'ee/analytics/code_review_analytics/store/state';
import * as getters from 'ee/analytics/code_review_analytics/store/getters';

describe('Code review analytics getteers', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('showMrCount', () => {
    it('returns false when is loading', () => {
      state = { isLoading: true, errorCode: null };

      expect(getters.showMrCount(state)).toBe(false);
    });

    it('returns true when not loading and no error', () => {
      state = { isLoading: false, errorCode: null };

      expect(getters.showMrCount(state)).toBe(true);
    });
  });
});
