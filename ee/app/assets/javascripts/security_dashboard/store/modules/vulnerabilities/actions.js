import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import createFlash from '~/flash';

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
    .post(vulnerability.vulnerability_feedback_issue_path, {
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

export const dismissVulnerability = ({ dispatch }, { vulnerability, flashError }) => {
  dispatch('requestDismissVulnerability');

  axios
    .post(vulnerability.vulnerability_feedback_dismissal_path, {
      vulnerability_feedback: {
        feedback_type: 'dismissal',
        category: vulnerability.report_type,
        project_fingerprint: vulnerability.project_fingerprint,
        vulnerability_data: {
          ...vulnerability,
          category: vulnerability.report_type,
        },
      },
    })
    .then(({ data }) => {
      const { id } = vulnerability;
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

export const revertDismissal = ({ dispatch }, { vulnerability, flashError }) => {
  const { vulnerability_feedback_dismissal_path, dismissal_feedback } = vulnerability;
  // eslint-disable-next-line camelcase
  const url = `${vulnerability_feedback_dismissal_path}/${dismissal_feedback.id}`;

  dispatch('requestRevertDismissal');

  axios
    .delete(url)
    .then(() => {
      const { id } = vulnerability;
      dispatch('receiveRevertDismissalSuccess', { id });
    })
    .catch(() => {
      dispatch('receiveRevertDismissalError', { flashError });
    });
};

export const requestRevertDismissal = ({ commit }) => {
  commit(types.REQUEST_REVERT_DISMISSAL);
};

export const receiveRevertDismissalSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_REVERT_DISMISSAL_SUCCESS, payload);
};

export const receiveRevertDismissalError = ({ commit }, { flashError }) => {
  commit(types.RECEIVE_REVERT_DISMISSAL_ERROR);
  if (flashError) {
    createFlash(
      s__('Security Reports|There was an error reverting this dismissal.'),
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

export const requestVulnerabilitiesHistory = ({ commit }) => {
  commit(types.REQUEST_VULNERABILITIES_HISTORY);
};

export const receiveVulnerabilitiesHistorySuccess = ({ commit }, { data }) => {
  commit(types.RECEIVE_VULNERABILITIES_HISTORY_SUCCESS, data);
};

export const receiveVulnerabilitiesHistoryError = ({ commit }) => {
  commit(types.RECEIVE_VULNERABILITIES_HISTORY_ERROR);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
// This is no longer needed after gitlab-ce#52179 is merged
export default () => {};
