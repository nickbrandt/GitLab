import * as types from './mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default {
  [types.SET_ENDPOINT](state, endpoint) {
    state.policiesEndpoint = endpoint;
  },
  [types.REQUEST_POLICIES](state) {
    state.isLoadingPolicies = true;
    state.errorLoadingPolicies = false;
  },
  [types.RECEIVE_POLICIES_SUCCESS](state, policies) {
    state.policies = policies.map(policy => convertObjectPropsToCamelCase(policy));
    state.isLoadingPolicies = false;
    state.errorLoadingPolicies = false;
  },
  [types.RECEIVE_POLICIES_ERROR](state) {
    state.isLoadingPolicies = false;
    state.errorLoadingPolicies = true;
  },
  [types.REQUEST_UPDATE_POLICY](state) {
    state.isUpdatingPolicy = true;
    state.errorUpdatingPolicy = false;
  },
  [types.RECEIVE_UPDATE_POLICY_SUCCESS](state, { policy, updatedPolicy }) {
    const newPolicy = convertObjectPropsToCamelCase(updatedPolicy);
    state.policies = state.policies.map(pol => (pol.name === policy.name ? newPolicy : pol));
    state.isUpdatingPolicy = false;
    state.errorUpdatingPolicy = false;
  },
  [types.RECEIVE_UPDATE_POLICY_ERROR](state) {
    state.isUpdatingPolicy = false;
    state.errorUpdatingPolicy = true;
  },
};
