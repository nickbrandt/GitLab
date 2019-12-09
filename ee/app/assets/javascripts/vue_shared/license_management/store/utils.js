import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';
import ReportMapper from 'ee/vue_shared/license_management/report_mapper';
import { n__, sprintf } from '~/locale';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/reports/constants';

const toLowerCase = name => name.toLowerCase();
/**
 *
 * Converts the snake case in license objects to camel case
 *
 * @param license {Object} License Object
 * @returns {Object}
 *
 */
export const normalizeLicense = license => {
  const { approval_status: approvalStatus, ...rest } = license;
  return {
    ...rest,
    approvalStatus,
  };
};

/**
 *
 * Comparator function for sorting licenses by name
 *
 * @param a {Object} License Object a
 * @param b {Object} License Object b
 * @returns {number}
 *
 * @example
 *
 * arrayOfLicenses.sort(byLicenseNameComparator)
 *
 */
export const byLicenseNameComparator = (a, b) => {
  const x = toLowerCase(a.name || '');
  const y = toLowerCase(b.name || '');
  if (x === y) {
    return 0;
  }
  return x > y ? 1 : -1;
};

export const getIssueStatusFromLicenseStatus = approvalStatus => {
  if (approvalStatus === LICENSE_APPROVAL_STATUS.APPROVED) {
    return STATUS_SUCCESS;
  } else if (approvalStatus === LICENSE_APPROVAL_STATUS.BLACKLISTED) {
    return STATUS_FAILED;
  }
  return STATUS_NEUTRAL;
};

const caseInsensitiveMatch = (name, otherName) => toLowerCase(name) === toLowerCase(otherName);
const getLicenseStatusByName = (managedLicenses = [], licenseName) =>
  managedLicenses.find(license => caseInsensitiveMatch(license.name, licenseName)) || {};

const getDependenciesByLicenseName = (dependencies = [], licenseName) =>
  dependencies.filter(dependencyItem => {
    const licenses = dependencyItem.licenses || [dependencyItem.license];
    return licenses.find(license => caseInsensitiveMatch(license.name, licenseName));
  });

/**
 *
 * Prepares a license report of the format:
 *
 * [
 *  {
 *   name: 'MIT',
 *   count: 1,
 *   url: 'https://spdx.org/MIT',
 *   packages: [{name: 'vue'}],
 *   approvalStatus: 'approved',
 *   id: 4,
 *  }
 * ]
 *
 * @param headMetrics {Object}
 *   License scanning report on head. Contains all found licenses and dependencies.
 * @param baseMetrics {Object}
 *   License scanning report on base. Contains all found licenses and dependencies.
 * @param managedLicenses {Array} List of licenses currently managed. (Approval Status)
 * @returns {Array}
 */
export const parseLicenseReportMetrics = (headMetrics, baseMetrics, managedLicenses) => {
  if (!headMetrics && !baseMetrics) {
    return [];
  }
  const reportMapper = new ReportMapper();
  const headReport = reportMapper.mapFrom(headMetrics);
  const baseReport = reportMapper.mapFrom(baseMetrics);

  const headLicenses = headReport.licenses || [];
  const headDependencies = headReport.dependencies || [];
  const baseLicenses = baseReport.licenses || [];
  const managedLicenseList = managedLicenses || [];

  if (!headLicenses.length && !headDependencies.length) return [];

  const knownLicenses = baseLicenses.map(license => toLowerCase(license.name));
  const identityMap = license => knownLicenses.includes(toLowerCase(license.name));
  const mapper = license => {
    const { name, count } = license;
    const { id, approvalStatus } = getLicenseStatusByName(managedLicenseList, name);
    const dependencies = getDependenciesByLicenseName(headDependencies, name);
    const url =
      license.url ||
      (dependencies && dependencies[0] && dependencies[0].license && dependencies[0].license.url) ||
      '';

    return {
      name,
      count,
      url,
      packages: dependencies.map(dependencyItem => dependencyItem.dependency),
      status: getIssueStatusFromLicenseStatus(approvalStatus),
      approvalStatus,
      id,
    };
  };

  return headLicenses
    .filter(license => !identityMap(license))
    .map(mapper)
    .sort(byLicenseNameComparator);
};

export const getPackagesString = (packages, truncate, maxPackages) => {
  const translatedMessage = n__(
    'ciReport|Used by %{packagesString}',
    'ciReport|Used by %{packagesString}, and %{lastPackage}',
    packages.length,
  );

  let packagesString;
  let lastPackage = '';

  if (packages.length === 1) {
    // When there is only 1 package name to show.
    packagesString = packages[0].name;
  } else if (truncate && packages.length > maxPackages) {
    // When packages count is higher than displayPackageCount
    // and truncate is true.
    packagesString = packages
      .slice(0, maxPackages)
      .map(packageItem => packageItem.name)
      .join(', ');
  } else {
    // Return all package names separated by comma with proper grammar
    packagesString = packages
      .slice(0, packages.length - 1)
      .map(packageItem => packageItem.name)
      .join(', ');
    lastPackage = packages[packages.length - 1].name;
  }

  return sprintf(translatedMessage, {
    packagesString,
    lastPackage,
  });
};

/**
 * This converts the newer licence format into the old one so we can use it with our older components.
 *
 * NOTE: This helper is temporary and can be removed once we flip the `parsedLicenseReport` feature flag
 * The below issue is for tracking its removal:
 * https://gitlab.com/gitlab-org/gitlab/issues/33878
 *
 * @param {Object} license The license in the newer format that needs converting
 * @returns {Object} The converted license;
 */

export const convertToOldReportFormat = license => {
  const approvalStatus = license.classification.approval_status;

  return {
    ...license,
    approvalStatus,
    id: license.classification.id,
    packages: license.dependencies,
    status: getIssueStatusFromLicenseStatus(approvalStatus),
  };
};
