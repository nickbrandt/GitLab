import * as types from './mutation_types';

export default {
  [types.SET_VULNERABILITIES_ENDPOINT](state, payload) {
    state.vulnerabilitiesEndpoint = payload;
  },
  [types.REQUEST_VULNERABILITIES](state) {
    state.isLoadingVulnerabilities = true;
    state.hasError = false;
  },
  [types.RECEIVE_VULNERABILITIES_SUCCESS](state, payload) {
    state.isLoadingVulnerabilities = false;
    state.pageInfo = payload.pageInfo;
    state.vulnerabilities = payload.vulnerabilities;
  },
  [types.RECEIVE_VULNERABILITIES_ERROR](state) {
    state.isLoadingVulnerabilities = false;
    state.hasError = true;
  },
  [types.SET_VULNERABILITIES_COUNT_ENDPOINT](state, payload) {
    state.vulnerabilitiesCountEndpoint = payload;
  },
  [types.REQUEST_VULNERABILITIES_COUNT](state) {
    state.isLoadingVulnerabilitiesCount = true;
    state.hasError = false;
  },
  [types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS](state, payload) {
    state.isLoadingVulnerabilitiesCount = false;
    state.vulnerabilitiesCount = payload;
  },
  [types.RECEIVE_VULNERABILITIES_COUNT_ERROR](state) {
    state.isLoadingVulnerabilitiesCount = false;
    state.hasError = true;
  },
};
