import * as types from 'ee/threat_monitoring/store/modules/network_policies/mutation_types';
import mutations from 'ee/threat_monitoring/store/modules/network_policies/mutations';

describe('Network Policies mutations', () => {
  let state;

  beforeEach(() => {
    state = {};
  });

  describe(types.SET_ENDPOINT, () => {
    it('sets the endpoints', () => {
      mutations[types.SET_ENDPOINT](state, 'policies');
      expect(state.policiesEndpoint).toEqual('policies');
    });
  });

  describe(types.REQUEST_POLICIES, () => {
    beforeEach(() => {
      mutations[types.REQUEST_POLICIES](state);
    });

    it('sets isLoadingPolicies to true and sets errorLoadingPolicies to false', () => {
      expect(state.isLoadingPolicies).toBe(true);
      expect(state.errorLoadingPolicies).toBe(false);
    });
  });

  describe(types.RECEIVE_POLICIES_SUCCESS, () => {
    let policies;

    beforeEach(() => {
      policies = [{ id: 1, name: 'production' }];
      mutations[types.RECEIVE_POLICIES_SUCCESS](state, policies);
    });

    it('sets policies to the payload', () => {
      expect(state.policies).toEqual(expect.objectContaining(policies));
    });

    it('sets isLoadingPolicies to false and sets errorLoadingPolicies to false', () => {
      expect(state.isLoadingPolicies).toBe(false);
      expect(state.errorLoadingPolicies).toBe(false);
    });
  });

  describe(types.RECEIVE_POLICIES_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_POLICIES_ERROR](state);
    });

    it('sets isLoadingPolicies to false and sets errorLoadingPolicies to true', () => {
      expect(state.isLoadingPolicies).toBe(false);
      expect(state.errorLoadingPolicies).toBe(true);
    });
  });
});
