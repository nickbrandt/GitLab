import Vue from 'vue';
import { s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import * as types from './mutation_types';

export default {
  [types.SET_VULNERABILITIES_ENDPOINT](state, payload) {
    state.vulnerabilitiesEndpoint = payload;
  },
  [types.REQUEST_VULNERABILITIES](state) {
    state.isLoadingVulnerabilities = true;
    state.errorLoadingVulnerabilities = false;
  },
  [types.RECEIVE_VULNERABILITIES_SUCCESS](state, payload) {
    state.isLoadingVulnerabilities = false;
    state.pageInfo = payload.pageInfo;
    state.vulnerabilities = payload.vulnerabilities;
  },
  [types.RECEIVE_VULNERABILITIES_ERROR](state) {
    state.isLoadingVulnerabilities = false;
    state.errorLoadingVulnerabilities = true;
  },
  [types.SET_VULNERABILITIES_COUNT_ENDPOINT](state, payload) {
    state.vulnerabilitiesCountEndpoint = payload;
  },
  [types.REQUEST_VULNERABILITIES_COUNT](state) {
    state.isLoadingVulnerabilitiesCount = true;
    state.errorLoadingVulnerabilitiesCount = false;
  },
  [types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS](state, payload) {
    state.isLoadingVulnerabilitiesCount = false;
    state.vulnerabilitiesCount = payload;
  },
  [types.RECEIVE_VULNERABILITIES_COUNT_ERROR](state) {
    state.isLoadingVulnerabilitiesCount = false;
    state.errorLoadingVulnerabilitiesCount = true;
  },
  [types.SET_VULNERABILITIES_HISTORY_ENDPOINT](state, payload) {
    state.vulnerabilitiesHistoryEndpoint = payload;
  },
  [types.REQUEST_VULNERABILITIES_HISTORY](state) {
    state.isLoadingVulnerabilitiesHistory = true;
    state.errorLoadingVulnerabilitiesHistory = false;
  },
  [types.RECEIVE_VULNERABILITIES_HISTORY_SUCCESS](state, payload) {
    state.isLoadingVulnerabilitiesHistory = false;
    state.vulnerabilitiesHistory = payload;
  },
  [types.RECEIVE_VULNERABILITIES_HISTORY_ERROR](state) {
    state.isLoadingVulnerabilitiesHistory = false;
    state.errorLoadingVulnerabilitiesHistory = true;
  },
  [types.SET_MODAL_DATA](state, payload) {
    const { vulnerability } = payload;

    Vue.set(state.modal, 'title', vulnerability.name);
    Vue.set(state.modal.data.description, 'value', vulnerability.description);
    Vue.set(
      state.modal.data.project,
      'value',
      vulnerability.project && vulnerability.project.full_name,
    );
    Vue.set(
      state.modal.data.project,
      'url',
      vulnerability.project && vulnerability.project.full_path,
    );
    Vue.set(state.modal.data.file, 'value', vulnerability.location && vulnerability.location.file);
    Vue.set(
      state.modal.data.identifiers,
      'value',
      vulnerability.identifiers.length && vulnerability.identifiers,
    );
    Vue.set(
      state.modal.data.className,
      'value',
      vulnerability.location && vulnerability.location.class,
    );
    Vue.set(state.modal.data.severity, 'value', vulnerability.severity);
    Vue.set(state.modal.data.confidence, 'value', vulnerability.confidence);
    Vue.set(state.modal, 'vulnerability', vulnerability);
    Vue.set(state.modal.vulnerability, 'hasIssue', Boolean(vulnerability.issue_feedback));
    Vue.set(state.modal.vulnerability, 'isDismissed', Boolean(vulnerability.dismissal_feedback));
    Vue.set(state.modal, 'error', null);

    if (vulnerability.instances && vulnerability.instances.length) {
      Vue.set(state.modal.data.instances, 'value', vulnerability.instances);
    } else {
      Vue.set(state.modal.data.instances, 'value', null);
    }

    if (vulnerability.links && vulnerability.links.length) {
      Vue.set(state.modal.data.links, 'value', vulnerability.links);
    } else {
      Vue.set(state.modal.data.links, 'value', null);
    }
  },
  [types.REQUEST_CREATE_ISSUE](state) {
    state.isCreatingIssue = true;
    Vue.set(state.modal, 'isCreatingNewIssue', true);
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_CREATE_ISSUE_SUCCESS](state, payload) {
    // We don't cancel the loading state here because we're navigating away from the page
    visitUrl(payload.issue_url);
  },
  [types.RECEIVE_CREATE_ISSUE_ERROR](state) {
    state.isCreatingIssue = false;
    Vue.set(state.modal, 'isCreatingNewIssue', false);
    Vue.set(state.modal, 'error', 'There was an error creating the issue');
  },
  [types.REQUEST_DISMISS_VULNERABILITY](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'isDismissingVulnerability', true);
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS](state, payload) {
    const vulnerability = state.vulnerabilities.find(vuln => vuln.id === payload.id);
    vulnerability.dismissal_feedback = payload.data;
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'isDismissingVulnerability', false);
    Vue.set(state.modal.vulnerability, 'isDismissed', true);
  },
  [types.RECEIVE_DISMISS_VULNERABILITY_ERROR](state) {
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'isDismissingVulnerability', false);
    Vue.set(
      state.modal,
      'error',
      s__('Security Reports|There was an error dismissing the vulnerability.'),
    );
  },
  [types.REQUEST_REVERT_DISMISSAL](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'isDismissingVulnerability', true);
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_REVERT_DISMISSAL_SUCCESS](state, payload) {
    const vulnerability = state.vulnerabilities.find(vuln => vuln.id === payload.id);
    vulnerability.dismissal_feedback = null;
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'isDismissingVulnerability', false);
    Vue.set(state.modal.vulnerability, 'isDismissed', false);
  },
  [types.RECEIVE_REVERT_DISMISSAL_ERROR](state) {
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'isDismissingVulnerability', false);
    Vue.set(
      state.modal,
      'error',
      s__('Security Reports|There was an error reverting the dismissal.'),
    );
  },
};
