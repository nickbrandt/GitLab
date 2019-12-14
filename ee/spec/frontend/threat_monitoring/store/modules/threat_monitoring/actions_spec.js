import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
import * as actions from 'ee/threat_monitoring/store/modules/threat_monitoring/actions';
import * as types from 'ee/threat_monitoring/store/modules/threat_monitoring/mutation_types';
import getInitialState from 'ee/threat_monitoring/store/modules/threat_monitoring/state';

describe('Threat Monitoring actions', () => {
  describe('setEndpoint', () => {
    it('commits the SET_ENDPOINT mutation', () =>
      testAction(
        actions.setEndpoint,
        TEST_HOST,
        getInitialState(),
        [
          {
            type: types.SET_ENDPOINT,
            payload: TEST_HOST,
          },
        ],
        [],
      ));
  });
});
