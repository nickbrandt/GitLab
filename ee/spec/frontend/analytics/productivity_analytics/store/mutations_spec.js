import SET_ENDPOINT from 'ee/analytics/productivity_analytics/store/mutation_types';
import mutations from 'ee/analytics/productivity_analytics/store/mutations';
import getInitialState from 'ee/analytics/productivity_analytics/store/state';

describe('Productivity analytics mutations', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  describe(SET_ENDPOINT, () => {
    it('sets the endpoint', () => {
      const endpoint = 'endpoint.json';
      mutations[SET_ENDPOINT](state, endpoint);

      expect(state.endpoint).toBe(endpoint);
    });
  });
});
