import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import * as types from './mutation_types';

export const setEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_ENDPOINT, endpoints.networkPoliciesEndpoint);
};

export const fetchPolicies = ({ state, commit }, environmentId) => {
  const commitError = payload => {
    const error =
      payload?.error || s__('NetworkPolicies|Something went wrong, unable to fetch policies');
    commit(types.RECEIVE_POLICIES_ERROR, error);
    createFlash(error);
  };

  if (!state.policiesEndpoint || !environmentId) return commitError();

  commit(types.REQUEST_POLICIES);

  return axios
    .get(state.policiesEndpoint, { params: { environment_id: environmentId } })
    .then(({ data }) => commit(types.RECEIVE_POLICIES_SUCCESS, data))
    .catch(error => commitError(error?.response?.data));
};
