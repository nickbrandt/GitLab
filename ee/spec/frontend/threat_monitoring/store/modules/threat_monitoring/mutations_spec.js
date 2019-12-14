import { TEST_HOST } from 'helpers/test_constants';
import * as types from 'ee/threat_monitoring/store/modules/threat_monitoring/mutation_types';
import mutations from 'ee/threat_monitoring/store/modules/threat_monitoring/mutations';
import getInitialState from 'ee/threat_monitoring/store/modules/threat_monitoring/state';

describe('Threat Monitoring mutations', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.SET_ENDPOINT, () => {
    it('sets the endpoint', () => {
      mutations[types.SET_ENDPOINT](state, TEST_HOST);

      expect(state.endpoint).toBe(TEST_HOST);
    });
  });
});
