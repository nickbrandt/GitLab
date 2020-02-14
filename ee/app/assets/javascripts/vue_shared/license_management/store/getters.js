import { n__, s__, sprintf } from '~/locale';
import { LICENSE_APPROVAL_STATUS } from '../constants';

export const isLoading = state => state.isLoadingManagedLicenses || state.isLoadingLicenseReport;

export const licenseReport = state => state.newLicenses;

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
            'LicenseCompliance|License Compliance detected %d license for the source branch only; approval required',
            'LicenseCompliance|License Compliance detected %d licenses for the source branch only; approval required',
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
          'LicenseCompliance|License Compliance detected %d new license; approval required',
          'LicenseCompliance|License Compliance detected %d new licenses; approval required',
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

export const reportContainsBlacklistedLicense = (_state, getters) =>
  (getters.licenseReport || []).some(
    license => license.approvalStatus === LICENSE_APPROVAL_STATUS.BLACKLISTED,
  );

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
