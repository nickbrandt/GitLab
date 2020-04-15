import { REPORT_STATUS } from './constants';
import { LICENSE_APPROVAL_CLASSIFICATION } from 'ee/vue_shared/license_compliance/constants';

export const isJobSetUp = state => state.reportInfo.status !== REPORT_STATUS.jobNotSetUp;
export const isJobFailed = state =>
  [REPORT_STATUS.jobFailed, REPORT_STATUS.noLicenses, REPORT_STATUS.incomplete].includes(
    state.reportInfo.status,
  );
export const hasPolicyViolations = state => {
  return state.licenses.some(
    license => license.classification === LICENSE_APPROVAL_CLASSIFICATION.DENIED,
  );
};
