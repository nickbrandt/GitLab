import Vue from 'vue';
import { s__, __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import getFileLocation from 'ee/vue_shared/security_reports/store/utils/get_file_location';
import * as types from './mutation_types';
import { DAYS } from './constants';
import { isSameVulnerability } from './utils';

export default {
  [types.SET_PIPELINE_ID](state, payload) {
    state.pipelineId = payload;
  },
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
  [types.SET_VULNERABILITIES_PAGE](state, payload) {
    state.pageInfo = { ...state.pageInfo, page: payload };
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
  [types.SET_VULNERABILITIES_HISTORY_DAY_RANGE](state, days) {
    state.vulnerabilitiesHistoryDayRange = days;

    if (days <= DAYS.THIRTY) {
      state.vulnerabilitiesHistoryMaxDayInterval = 7;
    } else if (days > DAYS.SIXTY) {
      state.vulnerabilitiesHistoryMaxDayInterval = 14;
    }
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
    const { location } = vulnerability;

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

    Vue.set(
      state.modal.data.identifiers,
      'value',
      vulnerability.identifiers.length && vulnerability.identifiers,
    );

    if (location) {
      const {
        file,
        start_line: startLine,
        end_line: endLine,
        image,
        operating_system: namespace,
        class: className,
      } = location;
      const fileLocation = getFileLocation(location);

      let lineSuffix = '';

      if (startLine) {
        lineSuffix += `:${startLine}`;
        if (endLine && startLine !== endLine) {
          lineSuffix += `-${endLine}`;
        }
      }

      Vue.set(state.modal.data.className, 'value', className);
      Vue.set(state.modal.data.file, 'value', file ? `${file}${lineSuffix}` : null);
      Vue.set(state.modal.data.image, 'value', image);
      Vue.set(state.modal.data.namespace, 'value', namespace);
      Vue.set(state.modal.data.url, 'value', fileLocation);
      Vue.set(state.modal.data.url, 'url', fileLocation);
    }

    Vue.set(state.modal.data.severity, 'value', vulnerability.severity);
    Vue.set(state.modal.data.reportType, 'value', vulnerability.report_type);
    Vue.set(state.modal.data.confidence, 'value', vulnerability.confidence);
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
    Vue.set(state.modal, 'error', __('There was an error creating the issue'));
  },
  [types.REQUEST_DISMISS_VULNERABILITY](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'isDismissingVulnerability', true);
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS](state, payload) {
    const vulnerability = state.vulnerabilities.find(vuln =>
      isSameVulnerability(vuln, payload.vulnerability),
    );
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
  [types.REQUEST_ADD_DISMISSAL_COMMENT](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'isDismissingVulnerability', true);
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS](state, payload) {
    const vulnerability = state.vulnerabilities.find(vuln =>
      isSameVulnerability(vuln, payload.vulnerability),
    );
    if (vulnerability) {
      vulnerability.dismissal_feedback = payload.data;
      state.isDismissingVulnerability = false;
      Vue.set(state.modal, 'isDismissingVulnerability', false);
      Vue.set(state.modal.vulnerability, 'isDismissed', true);
    }
  },
  [types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR](state) {
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'isDismissingVulnerability', false);
    Vue.set(state.modal, 'error', s__('Security Reports|There was an error adding the comment.'));
  },
  [types.REQUEST_DELETE_DISMISSAL_COMMENT](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'isDismissingVulnerability', true);
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS](state, payload) {
    const vulnerability = state.vulnerabilities.find(vuln => vuln.id === payload.id);
    if (vulnerability) {
      vulnerability.dismissal_feedback = payload.data;
      state.isDismissingVulnerability = false;
      Vue.set(state.modal, 'isDismissingVulnerability', false);
      Vue.set(state.modal.vulnerability, 'isDismissed', true);
    }
  },
  [types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR](state) {
    state.isDismissingVulnerability = false;
    Vue.set(state.modal, 'isDismissingVulnerability', false);
    Vue.set(state.modal, 'error', s__('Security Reports|There was an error deleting the comment.'));
  },
  [types.REQUEST_REVERT_DISMISSAL](state) {
    state.isDismissingVulnerability = true;
    Vue.set(state.modal, 'isDismissingVulnerability', true);
    Vue.set(state.modal, 'error', null);
  },
  [types.RECEIVE_REVERT_DISMISSAL_SUCCESS](state, payload) {
    const vulnerability = state.vulnerabilities.find(vuln =>
      isSameVulnerability(vuln, payload.vulnerability),
    );
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
  [types.SHOW_DISMISSAL_DELETE_BUTTONS](state) {
    Vue.set(state.modal, 'isShowingDeleteButtons', true);
  },
  [types.HIDE_DISMISSAL_DELETE_BUTTONS](state) {
    Vue.set(state.modal, 'isShowingDeleteButtons', false);
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
  [types.RECEIVE_CREATE_MERGE_REQUEST_ERROR](state) {
    state.isCreatingIssue = false;
    Vue.set(state.modal, 'isCreatingMergeRequest', false);
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
