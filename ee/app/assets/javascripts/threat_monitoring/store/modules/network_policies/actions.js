import { s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import createFlash, { FLASH_TYPES } from '~/flash';
import { joinPaths } from '~/lib/utils/url_utility';
import * as types from './mutation_types';

export const setEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_ENDPOINT, endpoints.networkPoliciesEndpoint);
};

const commitReceivePoliciesError = (commit, payload) => {
  const error =
    payload?.error || s__('NetworkPolicies|Something went wrong, unable to fetch policies');
  commit(types.RECEIVE_POLICIES_ERROR, error);
  createFlash(error);
};

export const fetchPolicies = ({ state, commit }, environmentId) => {
  if (!state.policiesEndpoint || !environmentId) return commitReceivePoliciesError(commit);

  commit(types.REQUEST_POLICIES);

  return axios
    .get(state.policiesEndpoint, { params: { environment_id: environmentId } })
    .then(({ data }) => commit(types.RECEIVE_POLICIES_SUCCESS, data))
    .catch(error => commitReceivePoliciesError(commit, error?.response?.data));
};

const commitUpdatePolicyError = (commit, payload) => {
  const error =
    payload?.error || s__('NetworkPolicies|Something went wrong, failed to update policy');
  commit(types.RECEIVE_UPDATE_POLICY_ERROR, error);
  createFlash(error);
};

export const updatePolicy = ({ state, commit }, { environmentId, policy }) => {
  if (!state.policiesEndpoint || !environmentId || !policy) {
    return commitUpdatePolicyError(commit);
  }

  commit(types.REQUEST_UPDATE_POLICY);

  return axios
    .put(joinPaths(state.policiesEndpoint, policy.name), {
      environment_id: environmentId,
      manifest: policy.manifest,
      enabled: policy.isEnabled,
    })
    .then(({ data }) => {
      commit(types.RECEIVE_UPDATE_POLICY_SUCCESS, {
        policy,
        updatedPolicy: data,
      });
      createFlash(
        sprintf(s__('NetworkPolicies|Policy %{policyName} was successfully changed'), {
          policyName: policy.name,
        }),
        FLASH_TYPES.SUCCESS,
      );
    })
    .catch(error => commitUpdatePolicyError(commit, error?.response?.data));
};
