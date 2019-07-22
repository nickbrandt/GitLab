import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import downloadPatchHelper from 'ee/vue_shared/security_reports/store/utils/download_patch_helper';
import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import createFlash from '~/flash';

/**
 * A lot of this file has duplicate actions in
 * ee/app/assets/javascripts/vue_shared/security_reports/store/actions.js
 * This is being addressed in the following issues:
 *
 * https://gitlab.com/gitlab-org/gitlab-ee/issues/8146
 * https://gitlab.com/gitlab-org/gitlab-ee/issues/8519
 */

const hideModal = () => $('#modal-mrwidget-security-issue').modal('hide');

export const setVulnerabilitiesEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_VULNERABILITIES_ENDPOINT, endpoint);
};

export const setVulnerabilitiesCountEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_VULNERABILITIES_COUNT_ENDPOINT, endpoint);
};

export const fetchVulnerabilitiesCount = ({ state, dispatch }, params = {}) => {
  if (!state.vulnerabilitiesCountEndpoint) {
    return;
  }
  dispatch('requestVulnerabilitiesCount');

  axios({
    method: 'GET',
    url: state.vulnerabilitiesCountEndpoint,
    params,
  })
    .then(response => {
      const { data } = response;
      dispatch('receiveVulnerabilitiesCountSuccess', { data });
    })
    .catch(() => {
      dispatch('receiveVulnerabilitiesCountError');
    });
};

export const requestVulnerabilitiesCount = ({ commit }) => {
  commit(types.REQUEST_VULNERABILITIES_COUNT);
};

export const receiveVulnerabilitiesCountSuccess = ({ commit }, { data }) => {
  commit(types.RECEIVE_VULNERABILITIES_COUNT_SUCCESS, data);
};

export const receiveVulnerabilitiesCountError = ({ commit }) => {
  commit(types.RECEIVE_VULNERABILITIES_COUNT_ERROR);
};

export const setVulnerabilitiesPage = ({ commit }, page) => {
  commit(types.SET_VULNERABILITIES_PAGE, page);
};

export const fetchVulnerabilities = ({ state, dispatch }, params = {}) => {
  if (!state.vulnerabilitiesEndpoint) {
    return;
  }
  dispatch('requestVulnerabilities');

  axios({
    method: 'GET',
    url: state.vulnerabilitiesEndpoint,
    params,
  })
    .then(response => {
      const { headers, data } = response;
      dispatch('receiveVulnerabilitiesSuccess', { headers, data });
    })
    .catch(() => {
      dispatch('receiveVulnerabilitiesError');
    });
};

export const requestVulnerabilities = ({ commit }) => {
  commit(types.REQUEST_VULNERABILITIES);
};

export const receiveVulnerabilitiesSuccess = ({ commit }, { headers, data }) => {
  const normalizedHeaders = normalizeHeaders(headers);
  const pageInfo = parseIntPagination(normalizedHeaders);
  const vulnerabilities = data;

  commit(types.RECEIVE_VULNERABILITIES_SUCCESS, { pageInfo, vulnerabilities });
};

export const receiveVulnerabilitiesError = ({ commit }) => {
  commit(types.RECEIVE_VULNERABILITIES_ERROR);
};

export const openModal = ({ commit }, payload = {}) => {
  $('#modal-mrwidget-security-issue').modal('show');

  commit(types.SET_MODAL_DATA, payload);
};

export const createIssue = ({ dispatch }, { vulnerability, flashError }) => {
  dispatch('requestCreateIssue');
  axios
    .post(vulnerability.create_vulnerability_feedback_issue_path, {
      vulnerability_feedback: {
        feedback_type: 'issue',
        category: vulnerability.report_type,
        project_fingerprint: vulnerability.project_fingerprint,
        vulnerability_data: {
          ...vulnerability,
          category: vulnerability.report_type,
        },
      },
    })
    .then(({ data }) => {
      dispatch('receiveCreateIssueSuccess', data);
    })
    .catch(() => {
      dispatch('receiveCreateIssueError', { flashError });
    });
};

export const requestCreateIssue = ({ commit }) => {
  commit(types.REQUEST_CREATE_ISSUE);
};

export const receiveCreateIssueSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_CREATE_ISSUE_SUCCESS, payload);
};

export const receiveCreateIssueError = ({ commit }, { flashError }) => {
  commit(types.RECEIVE_CREATE_ISSUE_ERROR);

  if (flashError) {
    createFlash(
      s__('Security Reports|There was an error creating the issue.'),
      'alert',
      document.querySelector('.ci-table'),
    );
  }
};

export const dismissVulnerability = ({ dispatch }, { vulnerability, flashError, comment }) => {
  dispatch('requestDismissVulnerability');

  axios
    .post(vulnerability.create_vulnerability_feedback_dismissal_path, {
      vulnerability_feedback: {
        category: vulnerability.report_type,
        comment,
        feedback_type: 'dismissal',
        project_fingerprint: vulnerability.project_fingerprint,
        vulnerability_data: {
          ...vulnerability,
          category: vulnerability.report_type,
        },
      },
    })
    .then(({ data }) => {
      const { id } = vulnerability;
      dispatch('closeDismissalCommentBox');
      dispatch('receiveDismissVulnerabilitySuccess', { id, data });
    })
    .catch(() => {
      dispatch('receiveDismissVulnerabilityError', { flashError });
    });
};

export const requestDismissVulnerability = ({ commit }) => {
  commit(types.REQUEST_DISMISS_VULNERABILITY);
};

export const receiveDismissVulnerabilitySuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS, payload);
  hideModal();
};

export const receiveDismissVulnerabilityError = ({ commit }, { flashError }) => {
  commit(types.RECEIVE_DISMISS_VULNERABILITY_ERROR);
  if (flashError) {
    createFlash(
      s__('Security Reports|There was an error dismissing the vulnerability.'),
      'alert',
      document.querySelector('.ci-table'),
    );
  }
};

export const addDismissalComment = ({ dispatch }, { vulnerability, comment }) => {
  dispatch('requestAddDismissalComment');

  const { dismissal_feedback } = vulnerability;
  const url = `${vulnerability.create_vulnerability_feedback_dismissal_path}/${dismissal_feedback.id}`;

  axios
    .patch(url, {
      project_id: dismissal_feedback.project_id,
      id: dismissal_feedback.id,
      comment,
    })
    .then(({ data }) => {
      const { id } = vulnerability;
      dispatch('closeDismissalCommentBox');
      dispatch('receiveAddDismissalCommentSuccess', { id, data });
    })
    .catch(() => {
      dispatch('receiveAddDismissalCommentError');
    });
};

export const deleteDismissalComment = ({ dispatch }, { vulnerability }) => {
  dispatch('requestDeleteDismissalComment');

  const { dismissal_feedback } = vulnerability;
  const url = `${vulnerability.create_vulnerability_feedback_dismissal_path}/${dismissal_feedback.id}`;

  axios
    .patch(url, {
      project_id: dismissal_feedback.project_id,
      comment: '',
    })
    .then(({ data }) => {
      const { id } = vulnerability;
      dispatch('closeDismissalCommentBox');
      dispatch('receiveDeleteDismissalCommentSuccess', { id, data });
    })
    .catch(() => {
      dispatch('receiveDeleteDismissalCommentError');
    });
};

export const requestAddDismissalComment = ({ commit }) => {
  commit(types.REQUEST_ADD_DISMISSAL_COMMENT);
};

export const receiveAddDismissalCommentSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS, payload);
  hideModal();
};

export const receiveAddDismissalCommentError = ({ commit }) => {
  commit(types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR);
};

export const requestDeleteDismissalComment = ({ commit }) => {
  commit(types.REQUEST_DELETE_DISMISSAL_COMMENT);
};

export const receiveDeleteDismissalCommentSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS, payload);
  hideModal();
};

export const receiveDeleteDismissalCommentError = ({ commit }) => {
  commit(types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR);
};

export const showDismissalDeleteButtons = ({ commit }) => {
  commit(types.SHOW_DISMISSAL_DELETE_BUTTONS);
};

export const hideDismissalDeleteButtons = ({ commit }) => {
  commit(types.HIDE_DISMISSAL_DELETE_BUTTONS);
};

export const undoDismiss = ({ dispatch }, { vulnerability, flashError }) => {
  const { destroy_vulnerability_feedback_dismissal_path } = vulnerability.dismissal_feedback;

  dispatch('requestUndoDismiss');

  axios
    .delete(destroy_vulnerability_feedback_dismissal_path)
    .then(() => {
      const { id } = vulnerability;
      dispatch('receiveUndoDismissSuccess', { id });
    })
    .catch(() => {
      dispatch('receiveUndoDismissError', { flashError });
    });
};

export const requestUndoDismiss = ({ commit }) => {
  commit(types.REQUEST_REVERT_DISMISSAL);
};

export const receiveUndoDismissSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_REVERT_DISMISSAL_SUCCESS, payload);
  hideModal();
};

export const receiveUndoDismissError = ({ commit }, { flashError }) => {
  commit(types.RECEIVE_REVERT_DISMISSAL_ERROR);
  if (flashError) {
    createFlash(
      s__('Security Reports|There was an error reverting this dismissal.'),
      'alert',
      document.querySelector('.ci-table'),
    );
  }
};

export const downloadPatch = ({ state }) => {
  /* 
    This action doesn't actually mutate the Vuex state and is a dirty
    workaround to modifying the dom. We do this because gl-split-button 
    relies on a old version of vue-bootstrap and it doesn't allow us to 
    set a href for a file download. 

    https://gitlab.com/gitlab-org/gitlab-ui/issues/188#note_165808493
  */
  const { vulnerability } = state.modal;
  downloadPatchHelper(vulnerability.remediations[0].diff);
  $('#modal-mrwidget-security-issue').modal('hide');
};

export const createMergeRequest = ({ dispatch }, { vulnerability, flashError }) => {
  const {
    report_type,
    project_fingerprint,
    create_vulnerability_feedback_merge_request_path,
  } = vulnerability;

  dispatch('requestCreateMergeRequest');

  axios
    .post(create_vulnerability_feedback_merge_request_path, {
      vulnerability_feedback: {
        feedback_type: 'merge_request',
        category: report_type,
        project_fingerprint,
        vulnerability_data: {
          ...vulnerability,
          category: report_type,
        },
      },
    })
    .then(({ data }) => {
      dispatch('receiveCreateMergeRequestSuccess', data);
    })
    .catch(() => {
      dispatch('receiveCreateMergeRequestError', { flashError });
    });
};

export const requestCreateMergeRequest = ({ commit }) => {
  commit(types.REQUEST_CREATE_MERGE_REQUEST);
};

export const receiveCreateMergeRequestSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS, payload);
};

export const receiveCreateMergeRequestError = ({ commit }, { flashError }) => {
  commit(types.RECEIVE_CREATE_MERGE_REQUEST_ERROR);

  if (flashError) {
    createFlash(
      s__('Security Reports|There was an error creating the merge request.'),
      'alert',
      document.querySelector('.ci-table'),
    );
  }
};

export const setVulnerabilitiesHistoryEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_VULNERABILITIES_HISTORY_ENDPOINT, endpoint);
};

export const fetchVulnerabilitiesHistory = ({ state, dispatch }, params = {}) => {
  if (!state.vulnerabilitiesHistoryEndpoint) {
    return;
  }
  dispatch('requestVulnerabilitiesHistory');

  axios({
    method: 'GET',
    url: state.vulnerabilitiesHistoryEndpoint,
    params,
  })
    .then(response => {
      const { data } = response;
      dispatch('receiveVulnerabilitiesHistorySuccess', { data });
    })
    .catch(() => {
      dispatch('receiveVulnerabilitiesHistoryError');
    });
};

export const setVulnerabilitiesHistoryDayRange = ({ commit }, days) => {
  commit(types.SET_VULNERABILITIES_HISTORY_DAY_RANGE, days);
};

export const requestVulnerabilitiesHistory = ({ commit }) => {
  commit(types.REQUEST_VULNERABILITIES_HISTORY);
};

export const receiveVulnerabilitiesHistorySuccess = ({ commit }, { data }) => {
  commit(types.RECEIVE_VULNERABILITIES_HISTORY_SUCCESS, data);
};

export const receiveVulnerabilitiesHistoryError = ({ commit }) => {
  commit(types.RECEIVE_VULNERABILITIES_HISTORY_ERROR);
};

export const openDismissalCommentBox = ({ commit }) => {
  commit(types.OPEN_DISMISSAL_COMMENT_BOX);
};

export const closeDismissalCommentBox = ({ commit }) => {
  commit(types.CLOSE_DISMISSAL_COMMENT_BOX);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
