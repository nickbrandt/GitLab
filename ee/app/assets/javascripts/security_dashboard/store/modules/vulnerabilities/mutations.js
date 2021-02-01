import Vue from 'vue';
import { s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import * as types from './mutation_types';
import { isSameVulnerability } from './utils';

export default {
  [types.SET_PIPELINE_ID](state, payload) {
    state.pipelineId = payload;
  },
  [types.SET_SOURCE_BRANCH](state, payload) {
    state.sourceBranch = payload;
  },
  [types.SET_VULNERABILITIES_ENDPOINT](state, payload) {
    state.vulnerabilitiesEndpoint = payload;
  },
  [types.REQUEST_VULNERABILITIES](state) {
    state.isLoadingVulnerabilities = true;
    state.errorLoadingVulnerabilities = false;
    state.loadingVulnerabilitiesErrorCode = null;
  },
  [types.RECEIVE_VULNERABILITIES_SUCCESS](state, payload) {
    state.isLoadingVulnerabilities = false;
    state.pageInfo = payload.pageInfo;
    state.vulnerabilities = payload.vulnerabilities;
    state.selectedVulnerabilities = {};
  },
  [types.RECEIVE_VULNERABILITIES_ERROR](state, errorCode = null) {
    state.isLoadingVulnerabilities = false;
    state.errorLoadingVulnerabilities = true;
    state.loadingVulnerabilitiesErrorCode = errorCode;
  },
  [types.SET_VULNERABILITIES_PAGE](state, payload) {
    state.pageInfo = { ...state.pageInfo, page: payload };
  },
  [types.SET_MODAL_DATA](state, payload) {
    const { vulnerability } = payload;

    Vue.set(state.modal, 'title', vulnerability.name);

    Vue.set(state.modal.project, 'value', vulnerability.project?.full_name);
    Vue.set(state.modal.project, 'url', vulnerability.project?.full_path);

    Vue.set(state.modal, 'vulnerability', vulnerability);
    Vue.set(
      state.modal.vulnerability,
      'hasIssue',
      Boolean(vulnerability.issue_feedback && vulnerability.issue_feedback.issue_iid),
    );
    Vue.set(
      state.modal.vulnerability,
      'hasMergeRequest',
      Boolean(
        vulnerability.merge_request_feedback &&
          vulnerability.merge_request_feedback.merge_request_iid,
      ),
    );
    Vue.set(state.modal.vulnerability, 'isDismissed', Boolean(vulnerability.dismissal_feedback));
    Vue.set(state.modal, 'error', null);
    Vue.set(state.modal, 'isCommentingOnDismissal', false);
  },
  [types.REQUEST_CREATE_ISSUE](state, vulnerability) {
    state.isCreatingIssue = true;
    visitUrl(vulnerability.create_vulnerability_feedback_issue_path, {
      params: { vulnerability_id: vulnerability.id },
    });
  },
  [types.REQUEST_DISMISS_VULNERABILITY](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS](state, payload) {
    const vulnerability = state.vulnerabilities.find((vuln) =>
      isSameVulnerability(vuln, payload.vulnerability),
    );
    vulnerability.dismissal_feedback = payload.data;
    state.isDismissingVulnerability = false;
    Vue.set(state.modal.vulnerability, 'isDismissed', true);
  },
  [types.RECEIVE_DISMISS_VULNERABILITY_ERROR](state) {
    state.isDismissingVulnerability = false;
    Vue.set(
      state.modal,
      'error',
      s__('SecurityReports|There was an error dismissing the vulnerability.'),
    );
  },
  [types.REQUEST_DISMISS_SELECTED_VULNERABILITIES](state) {
    state.isDismissingVulnerabilities = true;
  },
  [types.RECEIVE_DISMISS_SELECTED_VULNERABILITIES_SUCCESS](state) {
    state.isDismissingVulnerabilities = false;
    state.selectedVulnerabilities = {};
  },
  [types.RECEIVE_DISMISS_SELECTED_VULNERABILITIES_ERROR](state) {
    state.isDismissingVulnerabilities = false;
  },
  [types.SELECT_VULNERABILITY](state, id) {
    if (state.selectedVulnerabilities[id]) {
      return;
    }

    Vue.set(state.selectedVulnerabilities, id, true);
  },
  [types.DESELECT_VULNERABILITY](state, id) {
    Vue.delete(state.selectedVulnerabilities, id);
  },
  [types.SELECT_ALL_VULNERABILITIES](state) {
    state.selectedVulnerabilities = state.vulnerabilities.reduce(
      (acc, { id }) => Object.assign(acc, { [id]: true }),
      {},
    );
  },
  [types.DESELECT_ALL_VULNERABILITIES](state) {
    state.selectedVulnerabilities = {};
  },
  [types.REQUEST_ADD_DISMISSAL_COMMENT](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS](state, payload) {
    const vulnerability = state.vulnerabilities.find((vuln) =>
      isSameVulnerability(vuln, payload.vulnerability),
    );
    if (vulnerability) {
      vulnerability.dismissal_feedback = payload.data;
      state.isDismissingVulnerability = false;
      Vue.set(state.modal.vulnerability, 'isDismissed', true);
    }
  },
  [types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR](state) {
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'error', s__('SecurityReports|There was an error adding the comment.'));
  },
  [types.REQUEST_DELETE_DISMISSAL_COMMENT](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS](state, payload) {
    const vulnerability = state.vulnerabilities.find((vuln) => vuln.id === payload.id);
    if (vulnerability) {
      vulnerability.dismissal_feedback = payload.data;
      state.isDismissingVulnerability = false;
      Vue.set(state.modal.vulnerability, 'isDismissed', true);
    }
  },
  [types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR](state) {
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'error', s__('SecurityReports|There was an error deleting the comment.'));
  },
  [types.REQUEST_REVERT_DISMISSAL](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_REVERT_DISMISSAL_SUCCESS](state, payload) {
    const vulnerability = state.vulnerabilities.find((vuln) =>
      isSameVulnerability(vuln, payload.vulnerability),
    );
    vulnerability.dismissal_feedback = null;
    state.isDismissingVulnerability = false;
    Vue.set(state.modal.vulnerability, 'isDismissed', false);
  },
  [types.RECEIVE_REVERT_DISMISSAL_ERROR](state) {
    state.isDismissingVulnerability = false;
    Vue.set(
      state.modal,
      'error',
      s__('SecurityReports|There was an error reverting the dismissal.'),
    );
  },
  [types.SHOW_DISMISSAL_DELETE_BUTTONS](state) {
    Vue.set(state.modal, 'isShowingDeleteButtons', true);
  },
  [types.HIDE_DISMISSAL_DELETE_BUTTONS](state) {
    Vue.set(state.modal, 'isShowingDeleteButtons', false);
  },
  [types.REQUEST_CREATE_MERGE_REQUEST](state) {
    state.isCreatingMergeRequest = true;
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS](state, payload) {
    // We don't cancel the loading state here because we're navigating away from the page
    visitUrl(payload.merge_request_path);
  },
  [types.RECEIVE_CREATE_MERGE_REQUEST_ERROR](state) {
    state.isCreatingIssue = false;
    state.isCreatingMergeRequest = false;
    Vue.set(
      state.modal,
      'error',
      s__('security Reports|There was an error creating the merge request'),
    );
  },
  [types.OPEN_DISMISSAL_COMMENT_BOX](state) {
    Vue.set(state.modal, 'isCommentingOnDismissal', true);
  },
  [types.CLOSE_DISMISSAL_COMMENT_BOX](state) {
    Vue.set(state.modal, 'isShowingDeleteButtons', false);
    Vue.set(state.modal, 'isCommentingOnDismissal', false);
    Vue.set(state.modal, 'isShowingDeleteButtons', false);
  },
};
