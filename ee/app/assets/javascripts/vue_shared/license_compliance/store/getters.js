import { n__, s__, sprintf } from '~/locale';
import { addLicensesMatchingReportGroupStatus, reportGroupHasAtLeastOneLicense } from './utils';
import { LICENSE_APPROVAL_STATUS, REPORT_GROUPS } from '../constants';

export const isLoading = state => state.isLoadingManagedLicenses || state.isLoadingLicenseReport;

export const isLicenseBeingUpdated = state => (id = null) => state.pendingLicenses.includes(id);

export const isAddingNewLicense = (_, getters) => getters.isLicenseBeingUpdated();

export const hasPendingLicenses = state => state.pendingLicenses.length > 0;

export const licenseReport = state => state.newLicenses;

export const licenseReportGroups = state =>
  REPORT_GROUPS.map(addLicensesMatchingReportGroupStatus(state.newLicenses)).filter(
    reportGroupHasAtLeastOneLicense,
  );

export const licenseSummaryText = (state, getters) => {
  const hasReportItems = getters.licenseReport && getters.licenseReport.length;
  const baseReportHasLicenses = state.existingLicenses.length;

  if (getters.isLoading) {
    return sprintf(s__('ciReport|Loading %{reportName} report'), {
      reportName: s__('License Compliance'),
    });
  }

  if (state.loadLicenseReportError) {
    return sprintf(s__('ciReport|Failed to load %{reportName} report'), {
      reportName: s__('License Compliance'),
    });
  }

  if (hasReportItems) {
    const licenseReportLength = getters.licenseReport.length;

    if (!baseReportHasLicenses) {
      return getters.reportContainsBlacklistedLicense
        ? n__(
            'LicenseCompliance|License Compliance detected %d license and policy violation for the source branch only; approval required',
            'LicenseCompliance|License Compliance detected %d licenses and policy violations for the source branch only; approval required',
            licenseReportLength,
          )
        : n__(
            'LicenseCompliance|License Compliance detected %d license for the source branch only',
            'LicenseCompliance|License Compliance detected %d licenses for the source branch only',
            licenseReportLength,
          );
    }

    return getters.reportContainsBlacklistedLicense
      ? n__(
          'LicenseCompliance|License Compliance detected %d new license and policy violation; approval required',
          'LicenseCompliance|License Compliance detected %d new licenses and policy violations; approval required',
          licenseReportLength,
        )
      : n__(
          'LicenseCompliance|License Compliance detected %d new license',
          'LicenseCompliance|License Compliance detected %d new licenses',
          licenseReportLength,
        );
  }

  if (!baseReportHasLicenses) {
    return s__(
      'LicenseCompliance|License Compliance detected no licenses for the source branch only',
    );
  }

  return s__('LicenseCompliance|License Compliance detected no new licenses');
};

export const reportContainsBlacklistedLicense = (_, getters) =>
  (getters.licenseReport || []).some(
    license => license.approvalStatus === LICENSE_APPROVAL_STATUS.DENIED,
  );

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
