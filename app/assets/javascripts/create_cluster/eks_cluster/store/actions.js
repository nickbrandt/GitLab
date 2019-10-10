import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';

export default apiPaths => ({
  setClusterName({ commit }, payload) {
    commit(types.SET_CLUSTER_NAME, payload);
  },
  setEnvironmentScope({ commit }, payload) {
    commit(types.SET_ENVIRONMENT_SCOPE, payload);
  },
  setKubernetesVersion({ commit }, payload) {
    commit(types.SET_KUBERNETES_VERSION, payload);
  },
  createRole({ dispatch }, payload) {
    dispatch('requestCreateRole');

    return axios
      .post(apiPaths.createRolePath, {
        role_arn: payload.roleArn,
        role_external_id: payload.externalId,
      })
      .then(() => dispatch('createRoleSuccess'))
      .catch(error => dispatch('createRoleError', { error }));
  },
  requestCreateRole({ commit }) {
    commit(types.REQUEST_CREATE_ROLE);
  },
  createRoleSuccess({ commit }) {
    commit(types.CREATE_ROLE_SUCCESS);
  },
  createRoleError({ commit }, payload) {
    commit(types.CREATE_ROLE_ERROR, payload);
  },
  setRegion({ commit }, payload) {
    commit(types.SET_REGION, payload);
  },
  setKeyPair({ commit }, payload) {
    commit(types.SET_KEY_PAIR, payload);
  },
  setVpc({ commit }, payload) {
    commit(types.SET_VPC, payload);
  },
  setSubnet({ commit }, payload) {
    commit(types.SET_SUBNET, payload);
  },
  setRole({ commit }, payload) {
    commit(types.SET_ROLE, payload);
  },
  setSecurityGroup({ commit }, payload) {
    commit(types.SET_SECURITY_GROUP, payload);
  },
  setGitlabManagedCluster({ commit }, payload) {
    commit(types.SET_GITLAB_MANAGED_CLUSTER, payload);
  },
});
