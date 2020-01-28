import Vue from 'vue';
import * as types from './mutation_types';
import { findIssueIndex, parseDiff } from './utils';
import getFileLocation from './utils/get_file_location';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  [types.SET_HEAD_BLOB_PATH](state, path) {
    Vue.set(state.blobPath, 'head', path);
  },

  [types.SET_BASE_BLOB_PATH](state, path) {
    Vue.set(state.blobPath, 'base', path);
  },

  [types.SET_SOURCE_BRANCH](state, branch) {
    state.sourceBranch = branch;
  },

  [types.SET_VULNERABILITY_FEEDBACK_PATH](state, path) {
    state.vulnerabilityFeedbackPath = path;
  },

  [types.SET_VULNERABILITY_FEEDBACK_HELP_PATH](state, path) {
    state.vulnerabilityFeedbackHelpPath = path;
  },

  [types.SET_CREATE_VULNERABILITY_FEEDBACK_ISSUE_PATH](state, path) {
    state.createVulnerabilityFeedbackIssuePath = path;
  },

  [types.SET_CREATE_VULNERABILITY_FEEDBACK_MERGE_REQUEST_PATH](state, path) {
    state.createVulnerabilityFeedbackMergeRequestPath = path;
  },

  [types.SET_CREATE_VULNERABILITY_FEEDBACK_DISMISSAL_PATH](state, path) {
    state.createVulnerabilityFeedbackDismissalPath = path;
  },

  [types.SET_PIPELINE_ID](state, id) {
    state.pipelineId = id;
  },

  [types.SET_CAN_CREATE_ISSUE_PERMISSION](state, permission) {
    state.canCreateIssuePermission = permission;
  },

  [types.SET_CAN_CREATE_FEEDBACK_PERMISSION](state, permission) {
    state.canCreateFeedbackPermission = permission;
  },

  // CONTAINER SCANNING
  [types.SET_CONTAINER_SCANNING_DIFF_ENDPOINT](state, path) {
    Vue.set(state.containerScanning.paths, 'diffEndpoint', path);
  },

  [types.REQUEST_CONTAINER_SCANNING_DIFF](state) {
    Vue.set(state.containerScanning, 'isLoading', true);
  },

  [types.RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS](state, { diff, enrichData }) {
    const { added, fixed, existing } = parseDiff(diff, enrichData);
    const baseReportOutofDate = diff.base_report_out_of_date || false;
    const hasBaseReport = Boolean(diff.base_report_created_at);

    Vue.set(state.containerScanning, 'isLoading', false);
    Vue.set(state.containerScanning, 'newIssues', added);
    Vue.set(state.containerScanning, 'resolvedIssues', fixed);
    Vue.set(state.containerScanning, 'allIssues', existing);
    Vue.set(state.containerScanning, 'baseReportOutofDate', baseReportOutofDate);
    Vue.set(state.containerScanning, 'hasBaseReport', hasBaseReport);
  },

  [types.RECEIVE_CONTAINER_SCANNING_DIFF_ERROR](state) {
    Vue.set(state.containerScanning, 'isLoading', false);
    Vue.set(state.containerScanning, 'hasError', true);
  },

  // DAST

  [types.SET_DAST_DIFF_ENDPOINT](state, path) {
    Vue.set(state.dast.paths, 'diffEndpoint', path);
  },

  [types.REQUEST_DAST_DIFF](state) {
    Vue.set(state.dast, 'isLoading', true);
  },

  [types.RECEIVE_DAST_DIFF_SUCCESS](state, { diff, enrichData }) {
    const { added, fixed, existing } = parseDiff(diff, enrichData);
    const baseReportOutofDate = diff.base_report_out_of_date || false;
    const hasBaseReport = Boolean(diff.base_report_created_at);

    Vue.set(state.dast, 'isLoading', false);
    Vue.set(state.dast, 'newIssues', added);
    Vue.set(state.dast, 'resolvedIssues', fixed);
    Vue.set(state.dast, 'allIssues', existing);
    Vue.set(state.dast, 'baseReportOutofDate', baseReportOutofDate);
    Vue.set(state.dast, 'hasBaseReport', hasBaseReport);
  },

  [types.RECEIVE_DAST_DIFF_ERROR](state) {
    Vue.set(state.dast, 'isLoading', false);
    Vue.set(state.dast, 'hasError', true);
  },

  // DEPENDECY SCANNING

  [types.SET_DEPENDENCY_SCANNING_DIFF_ENDPOINT](state, path) {
    Vue.set(state.dependencyScanning.paths, 'diffEndpoint', path);
  },

  [types.REQUEST_DEPENDENCY_SCANNING_DIFF](state) {
    Vue.set(state.dependencyScanning, 'isLoading', true);
  },

  [types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS](state, { diff, enrichData }) {
    const { added, fixed, existing } = parseDiff(diff, enrichData);
    const baseReportOutofDate = diff.base_report_out_of_date || false;
    const hasBaseReport = Boolean(diff.base_report_created_at);

    Vue.set(state.dependencyScanning, 'isLoading', false);
    Vue.set(state.dependencyScanning, 'newIssues', added);
    Vue.set(state.dependencyScanning, 'resolvedIssues', fixed);
    Vue.set(state.dependencyScanning, 'allIssues', existing);
    Vue.set(state.dependencyScanning, 'baseReportOutofDate', baseReportOutofDate);
    Vue.set(state.dependencyScanning, 'hasBaseReport', hasBaseReport);
  },

  [types.RECEIVE_DEPENDENCY_SCANNING_DIFF_ERROR](state) {
    Vue.set(state.dependencyScanning, 'isLoading', false);
    Vue.set(state.dependencyScanning, 'hasError', true);
  },

  [types.SET_ISSUE_MODAL_DATA](state, payload) {
    const { issue, status } = payload;
    const fileLocation = getFileLocation(issue.location);

    Vue.set(state.modal, 'title', issue.title);
    Vue.set(state.modal.data.description, 'value', issue.description);
    Vue.set(state.modal.data.file, 'value', issue.location && issue.location.file);
    Vue.set(state.modal.data.file, 'url', issue.urlPath);
    Vue.set(state.modal.data.className, 'value', issue.location && issue.location.class);
    Vue.set(state.modal.data.methodName, 'value', issue.location && issue.location.method);
    Vue.set(state.modal.data.image, 'value', issue.location && issue.location.image);
    Vue.set(state.modal.data.namespace, 'value', issue.location && issue.location.operating_system);
    Vue.set(state.modal.data.url, 'value', fileLocation);
    Vue.set(state.modal.data.url, 'url', fileLocation);

    if (issue.identifiers && issue.identifiers.length > 0) {
      Vue.set(state.modal.data.identifiers, 'value', issue.identifiers);
    } else {
      // Force a null value for identifiers to avoid showing an empty array
      Vue.set(state.modal.data.identifiers, 'value', null);
    }

    Vue.set(state.modal.data.severity, 'value', issue.severity);
    Vue.set(state.modal.data.confidence, 'value', issue.confidence);

    if (issue.links && issue.links.length > 0) {
      Vue.set(state.modal.data.links, 'value', issue.links);
    } else {
      // Force a null value for links to avoid showing an empty array
      Vue.set(state.modal.data.links, 'value', null);
    }

    Vue.set(state.modal.data.instances, 'value', issue.instances);
    Vue.set(state.modal, 'vulnerability', issue);
    Vue.set(state.modal, 'isResolved', status === 'success');

    // clear previous state
    Vue.set(state.modal, 'error', null);
  },

  [types.REQUEST_DISMISS_VULNERABILITY](state) {
    Vue.set(state.modal, 'isDismissingVulnerability', true);
    // reset error in case previous state was error
    Vue.set(state.modal, 'error', null);
  },

  [types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS](state) {
    Vue.set(state.modal, 'isDismissingVulnerability', false);
  },

  [types.RECEIVE_DISMISS_VULNERABILITY_ERROR](state, error) {
    Vue.set(state.modal, 'error', error);
    Vue.set(state.modal, 'isDismissingVulnerability', false);
  },

  [types.REQUEST_ADD_DISMISSAL_COMMENT](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'isDismissingVulnerability', true);
    Vue.set(state.modal, 'error', null);
  },

  [types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS](state, payload) {
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'isDismissingVulnerability', false);
    Vue.set(state.modal.vulnerability, 'isDismissed', true);
    Vue.set(state.modal.vulnerability, 'dismissalFeedback', payload.data);
  },

  [types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR](state, error) {
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'isDismissingVulnerability', false);
    Vue.set(state.modal, 'error', error);
  },
  [types.REQUEST_DELETE_DISMISSAL_COMMENT](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'isDismissingVulnerability', true);
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS](state, payload) {
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'isDismissingVulnerability', false);
    Vue.set(state.modal.vulnerability, 'isDismissed', true);
    Vue.set(state.modal.vulnerability, 'dismissalFeedback', payload.data);
  },
  [types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR](state, error) {
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'isDismissingVulnerability', false);
    Vue.set(state.modal, 'error', error);
  },
  [types.SHOW_DISMISSAL_DELETE_BUTTONS](state) {
    Vue.set(state.modal, 'isShowingDeleteButtons', true);
  },
  [types.HIDE_DISMISSAL_DELETE_BUTTONS](state) {
    Vue.set(state.modal, 'isShowingDeleteButtons', false);
  },
  [types.UPDATE_DEPENDENCY_SCANNING_ISSUE](state, issue) {
    // Find issue in the correct list and update it

    const newIssuesIndex = findIssueIndex(state.dependencyScanning.newIssues, issue);
    if (newIssuesIndex !== -1) {
      state.dependencyScanning.newIssues.splice(newIssuesIndex, 1, issue);
      return;
    }

    const resolvedIssuesIndex = findIssueIndex(state.dependencyScanning.resolvedIssues, issue);
    if (resolvedIssuesIndex !== -1) {
      state.dependencyScanning.resolvedIssues.splice(resolvedIssuesIndex, 1, issue);
      return;
    }

    const allIssuesIndex = findIssueIndex(state.dependencyScanning.allIssues, issue);
    if (allIssuesIndex !== -1) {
      state.dependencyScanning.allIssues.splice(allIssuesIndex, 1, issue);
    }
  },

  [types.UPDATE_CONTAINER_SCANNING_ISSUE](state, issue) {
    // Find issue in the correct list and update it

    const newIssuesIndex = findIssueIndex(state.containerScanning.newIssues, issue);
    if (newIssuesIndex !== -1) {
      state.containerScanning.newIssues.splice(newIssuesIndex, 1, issue);
      return;
    }

    const resolvedIssuesIndex = findIssueIndex(state.containerScanning.resolvedIssues, issue);
    if (resolvedIssuesIndex !== -1) {
      state.containerScanning.resolvedIssues.splice(resolvedIssuesIndex, 1, issue);
    }
  },

  [types.UPDATE_DAST_ISSUE](state, issue) {
    // Find issue in the correct list and update it

    const newIssuesIndex = findIssueIndex(state.dast.newIssues, issue);
    if (newIssuesIndex !== -1) {
      state.dast.newIssues.splice(newIssuesIndex, 1, issue);
      return;
    }

    const resolvedIssuesIndex = findIssueIndex(state.dast.resolvedIssues, issue);
    if (resolvedIssuesIndex !== -1) {
      state.dast.resolvedIssues.splice(resolvedIssuesIndex, 1, issue);
    }
  },

  [types.REQUEST_CREATE_ISSUE](state) {
    Vue.set(state.modal, 'isCreatingNewIssue', true);
    // reset error in case previous state was error
    Vue.set(state.modal, 'error', null);
  },

  [types.RECEIVE_CREATE_ISSUE_SUCCESS](state) {
    Vue.set(state.modal, 'isCreatingNewIssue', false);
  },

  [types.RECEIVE_CREATE_ISSUE_ERROR](state, error) {
    Vue.set(state.modal, 'error', error);
    Vue.set(state.modal, 'isCreatingNewIssue', false);
  },

  [types.REQUEST_CREATE_MERGE_REQUEST](state) {
    state.isCreatingMergeRequest = true;
    Vue.set(state.modal, 'isCreatingMergeRequest', true);
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS](state, payload) {
    // We don't cancel the loading state here because we're navigating away from the page
    visitUrl(payload.merge_request_path);
  },
  [types.RECEIVE_CREATE_MERGE_REQUEST_ERROR](state, error) {
    state.isCreatingMergeRequest = false;
    Vue.set(state.modal, 'isCreatingMergeRequest', false);
    Vue.set(state.modal, 'error', error);
  },
  [types.OPEN_DISMISSAL_COMMENT_BOX](state) {
    Vue.set(state.modal, 'isCommentingOnDismissal', true);
  },
  [types.CLOSE_DISMISSAL_COMMENT_BOX](state) {
    Vue.set(state.modal, 'isShowingDeleteButtons', false);
    Vue.set(state.modal, 'isCommentingOnDismissal', false);
  },
};
