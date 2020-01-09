import * as types from 'ee/threat_monitoring/store/modules/threat_monitoring/mutation_types';
import mutations from 'ee/threat_monitoring/store/modules/threat_monitoring/mutations';
import { mockWafStatisticsResponse } from '../../../mock_data';

describe('Threat Monitoring mutations', () => {
  let state;

  beforeEach(() => {
    state = {};
  });

  describe(types.SET_ENDPOINTS, () => {
    it('sets the endpoints', () => {
      const endpoints = { wafStatisticsEndpoint: 'waf', environmentsEndpoint: 'envs' };

      mutations[types.SET_ENDPOINTS](state, endpoints);

      expect(state).toEqual(expect.objectContaining(endpoints));
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

  describe(types.REQUEST_WAF_STATISTICS, () => {
    beforeEach(() => {
      mutations[types.REQUEST_WAF_STATISTICS](state);
    });

    it('sets isLoadingWafStatistics to true', () => {
      expect(state.isLoadingWafStatistics).toBe(true);
    });

    it('sets errorLoadingWafStatistics to false', () => {
      expect(state.errorLoadingWafStatistics).toBe(false);
    });
  });

  describe(types.RECEIVE_WAF_STATISTICS_SUCCESS, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_WAF_STATISTICS_SUCCESS](state, mockWafStatisticsResponse);
    });

    it('sets wafStatistics according to the payload', () => {
      expect(state.wafStatistics).toEqual({
        totalTraffic: mockWafStatisticsResponse.total_traffic,
        anomalousTraffic: mockWafStatisticsResponse.anomalous_traffic,
        history: mockWafStatisticsResponse.history,
      });
    });

    it('sets isLoadingWafStatistics to false', () => {
      expect(state.isLoadingWafStatistics).toBe(false);
    });

    it('sets errorLoadingWafStatistics to false', () => {
      expect(state.errorLoadingWafStatistics).toBe(false);
    });
  });

  describe(types.RECEIVE_WAF_STATISTICS_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_WAF_STATISTICS_ERROR](state);
    });

    it('sets isLoadingWafStatistics to false', () => {
      expect(state.isLoadingWafStatistics).toBe(false);
    });

    it('sets errorLoadingWafStatistics to true', () => {
      expect(state.errorLoadingWafStatistics).toBe(true);
    });
  });
});
