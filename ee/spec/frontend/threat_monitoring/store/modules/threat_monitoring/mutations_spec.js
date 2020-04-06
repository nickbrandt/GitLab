import * as types from 'ee/threat_monitoring/store/modules/threat_monitoring/mutation_types';
import mutations from 'ee/threat_monitoring/store/modules/threat_monitoring/mutations';

describe('Threat Monitoring mutations', () => {
  let state;

  beforeEach(() => {
    state = {};
  });

  describe(types.SET_ENDPOINT, () => {
    it('sets the endpoints', () => {
      mutations[types.SET_ENDPOINT](state, 'envs');
      expect(state.environmentsEndpoint).toEqual('envs');
    });
  });

  describe(types.REQUEST_ENVIRONMENTS, () => {
    beforeEach(() => {
      mutations[types.REQUEST_ENVIRONMENTS](state);
    });

    it('sets isLoadingEnvironments to true', () => {
      expect(state.isLoadingEnvironments).toBe(true);
    });

    it('sets errorLoadingEnvironments to false', () => {
      expect(state.errorLoadingEnvironments).toBe(false);
    });
  });

  describe(types.RECEIVE_ENVIRONMENTS_SUCCESS, () => {
    let environments;

    beforeEach(() => {
      environments = [{ id: 1, name: 'production' }];
      mutations[types.RECEIVE_ENVIRONMENTS_SUCCESS](state, environments);
    });

    it('sets environments to the payload', () => {
      expect(state.environments).toBe(environments);
    });

    it('sets isLoadingEnvironments to false', () => {
      expect(state.isLoadingEnvironments).toBe(false);
    });

    it('sets errorLoadingEnvironments to false', () => {
      expect(state.errorLoadingEnvironments).toBe(false);
    });
  });

  describe(types.RECEIVE_ENVIRONMENTS_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_ENVIRONMENTS_ERROR](state);
    });

    it('sets isLoadingEnvironments to false', () => {
      expect(state.isLoadingEnvironments).toBe(false);
    });

    it('sets errorLoadingEnvironments to true', () => {
      expect(state.errorLoadingEnvironments).toBe(true);
    });
  });

  describe(types.SET_CURRENT_ENVIRONMENT_ID, () => {
    const environmentId = 3;

    beforeEach(() => {
      mutations[types.SET_CURRENT_ENVIRONMENT_ID](state, environmentId);
    });

    it('sets currentEnvironmentId', () => {
      expect(state.currentEnvironmentId).toBe(environmentId);
    });
  });

  describe(types.SET_CURRENT_TIME_WINDOW, () => {
    const timeWindow = 'foo';

    beforeEach(() => {
      mutations[types.SET_CURRENT_TIME_WINDOW](state, timeWindow);
    });

    it('sets currentTimeWindow', () => {
      expect(state.currentTimeWindow).toBe(timeWindow);
    });
  });
});
