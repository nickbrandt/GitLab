import axios from '~/lib/utils/axios_utils';
import pollUntilComplete from '~/lib/utils/poll_until_complete';
import * as types from './mutation_types';
import { LICENSE_APPROVAL_STATUS } from '../constants';
import { convertToOldReportFormat } from './utils';

export const setAPISettings = ({ commit }, data) => {
  commit(types.SET_API_SETTINGS, data);
};

export const setLicenseInModal = ({ commit }, license) => {
  commit(types.SET_LICENSE_IN_MODAL, license);
};
export const resetLicenseInModal = ({ commit }) => {
  commit(types.RESET_LICENSE_IN_MODAL);
};

export const requestDeleteLicense = ({ commit }) => {
  commit(types.REQUEST_DELETE_LICENSE);
};
export const receiveDeleteLicense = ({ commit, dispatch }) => {
  commit(types.RECEIVE_DELETE_LICENSE);
  dispatch('fetchManagedLicenses');
};
export const receiveDeleteLicenseError = ({ commit }, error) => {
  commit(types.RECEIVE_DELETE_LICENSE_ERROR, error);
};
export const deleteLicense = ({ dispatch, state }) => {
  const licenseId = state.currentLicenseInModal.id;
  dispatch('requestDeleteLicense');
  const endpoint = `${state.apiUrlManageLicenses}/${licenseId}`;
  return axios
    .delete(endpoint)
    .then(() => {
      dispatch('receiveDeleteLicense');
    })
    .catch(error => {
      dispatch('receiveDeleteLicenseError', error);
    });
};

export const requestManagedLicenses = ({ commit }) => {
  commit(types.REQUEST_MANAGED_LICENSES);
};
export const receiveManagedLicensesSuccess = ({ commit }, licenses) => {
  commit(types.RECEIVE_MANAGED_LICENSES_SUCCESS, licenses);
};
export const receiveManagedLicensesError = ({ commit }, error) => {
  commit(types.RECEIVE_MANAGED_LICENSES_ERROR, error);
};
export const fetchManagedLicenses = ({ dispatch, state }) => {
  dispatch('requestManagedLicenses');

  const { apiUrlManageLicenses } = state;

  return axios
    .get(apiUrlManageLicenses, { params: { per_page: 100 } })
    .then(({ data }) => {
      dispatch('receiveManagedLicensesSuccess', data);
    })
    .catch(error => {
      dispatch('receiveManagedLicensesError', error);
    });
};

export const requestParsedLicenseReport = ({ commit }) => {
  commit(types.REQUEST_PARSED_LICENSE_REPORT);
};
export const receiveParsedLicenseReportSuccess = ({ commit }, reports) => {
  commit(types.RECEIVE_PARSED_LICENSE_REPORT_SUCCESS, reports);
};
export const receiveParsedLicenseReportError = ({ commit }, error) => {
  commit(types.RECEIVE_PARSED_LICENSE_REPORT_ERROR, error);
};
export const fetchParsedLicenseReport = ({ dispatch, state }) => {
  dispatch('requestParsedLicenseReport');

  pollUntilComplete(state.licensesApiPath)
    .then(({ data }) => {
      const newLicenses = (data.new_licenses || data).map(convertToOldReportFormat);
      const existingLicenses = (data.existing_licenses || []).map(convertToOldReportFormat);
      dispatch('receiveParsedLicenseReportSuccess', { newLicenses, existingLicenses });
    })
    .catch(error => {
      dispatch('receiveParsedLicenseReportError', error);
    });
};

export const requestSetLicenseApproval = ({ commit }) => {
  commit(types.REQUEST_SET_LICENSE_APPROVAL);
};
export const receiveSetLicenseApproval = ({ commit, dispatch, state }) => {
  commit(types.RECEIVE_SET_LICENSE_APPROVAL);
  // If we have the licenses API endpoint, fetch from there. This corresponds
  // to the cases that we're viewing the merge request or pipeline pages.
  // Otherwise, fetch from the managed licenses endpoint, which corresponds to
  // the project settings page.
  // https://gitlab.com/gitlab-org/gitlab/issues/201867
  if (state.licensesApiPath) {
    dispatch('fetchParsedLicenseReport');
  } else {
    dispatch('fetchManagedLicenses');
  }
};
export const receiveSetLicenseApprovalError = ({ commit }, error) => {
  commit(types.RECEIVE_SET_LICENSE_APPROVAL_ERROR, error);
};

export const setIsAdmin = ({ commit }, payload) => {
  commit(types.SET_IS_ADMIN, payload);
};

export const setLicenseApproval = ({ dispatch, state }, payload) => {
  const { apiUrlManageLicenses } = state;
  const { license, newStatus } = payload;
  const { id, name } = license;

  dispatch('requestSetLicenseApproval');

  let request;

  /*
   Licenses that have an ID, are already in the database.
   So we need to send PATCH instead of POST.
   */
  if (id) {
    request = axios.patch(`${apiUrlManageLicenses}/${id}`, { approval_status: newStatus });
  } else {
    request = axios.post(apiUrlManageLicenses, { approval_status: newStatus, name });
  }

  return request
    .then(() => {
      dispatch('receiveSetLicenseApproval');
    })
    .catch(error => {
      dispatch('receiveSetLicenseApprovalError', error);
    });
};
export const approveLicense = ({ dispatch }, license) => {
  const { approvalStatus } = license;
  if (approvalStatus !== LICENSE_APPROVAL_STATUS.APPROVED) {
    dispatch('setLicenseApproval', { license, newStatus: LICENSE_APPROVAL_STATUS.APPROVED });
  }
};

export const blacklistLicense = ({ dispatch }, license) => {
  const { approvalStatus } = license;
  if (approvalStatus !== LICENSE_APPROVAL_STATUS.BLACKLISTED) {
    dispatch('setLicenseApproval', { license, newStatus: LICENSE_APPROVAL_STATUS.BLACKLISTED });
  }
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
