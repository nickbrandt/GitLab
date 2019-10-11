import { n__, s__, sprintf } from '~/locale';
import { parseLicenseReportMetrics } from './utils';

export const isLoading = state => state.isLoadingManagedLicenses || state.isLoadingLicenseReport;

export const licenseReport = state =>
  gon.features && gon.features.parsedLicenseReport
    ? state.newLicenses
    : parseLicenseReportMetrics(state.headReport, state.baseReport, state.managedLicenses);

export const licenseSummaryText = (state, getters) => {
  const hasReportItems = getters.licenseReport && getters.licenseReport.length;
  const baseReportHasLicenses =
    state.existingLicenses.length ||
    (state.baseReport && state.baseReport.licenses && state.baseReport.licenses.length);

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
    if (!baseReportHasLicenses) {
      return n__(
        'LicenseCompliance|License Compliance detected %d license for the source branch only',
        'LicenseCompliance|License Compliance detected %d licenses for the source branch only',
        getters.licenseReport.length,
      );
    }

    return n__(
      'LicenseCompliance|License Compliance detected %d new license',
      'LicenseCompliance|License Compliance detected %d new licenses',
      getters.licenseReport.length,
    );
  }

  if (!baseReportHasLicenses) {
    return s__(
      'LicenseCompliance|License Compliance detected no licenses for the source branch only',
    );
  }

  return s__('LicenseCompliance|License Compliance detected no new licenses');
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
