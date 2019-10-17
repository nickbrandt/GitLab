import {
  parseLicenseReportMetrics,
  byLicenseNameComparator,
  normalizeLicense,
  getPackagesString,
  getIssueStatusFromLicenseStatus,
  convertToOldReportFormat,
} from 'ee/vue_shared/license_management/store/utils';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/reports/constants';
import {
  approvedLicense,
  blacklistedLicense,
  licenseHeadIssues,
  licenseBaseIssues,
  licenseReport,
} from 'ee_spec/license_management/mock_data';

describe('utils', () => {
  describe('parseLicenseReportMetrics', () => {
    it('should return empty result, if no parameters are given', () => {
      const result = parseLicenseReportMetrics();

      expect(result).toEqual(jasmine.any(Array));
      expect(result.length).toEqual(0);
    });

    it('should return empty result, if license head report is empty', () => {
      const result = parseLicenseReportMetrics({ licenses: [] }, licenseBaseIssues);

      expect(result).toEqual(jasmine.any(Array));
      expect(result.length).toEqual(0);
    });

    it('should parse the received issues', () => {
      const result = parseLicenseReportMetrics(licenseHeadIssues, licenseBaseIssues);

      expect(result[0].name).toBe(licenseHeadIssues.licenses[0].name);
      expect(result[0].url).toBe(licenseHeadIssues.dependencies[0].license.url);
    });

    it('should omit issues from base report', () => {
      const knownLicenseName = licenseBaseIssues.licenses[0].name;
      const result = parseLicenseReportMetrics(licenseHeadIssues, licenseBaseIssues);

      expect(result.length).toBe(licenseHeadIssues.licenses.length - 1);
      expect(result[0].packages.length).toBe(licenseHeadIssues.dependencies.length - 1);
      result.forEach(license => {
        expect(license.name).not.toBe(knownLicenseName);
      });
    });

    it('should enrich the report with information from managed licenses report', () => {
      const result = parseLicenseReportMetrics(licenseHeadIssues, {}, [
        approvedLicense,
        blacklistedLicense,
      ]);

      expect(result.length).toBe(2);
      expect(result[0].approvalStatus).toBe(approvedLicense.approvalStatus);
      expect(result[0].id).toBe(approvedLicense.id);
      expect(result[1].approvalStatus).toBe(blacklistedLicense.approvalStatus);
      expect(result[1].id).toBe(blacklistedLicense.id);
    });

    it('matches using a case insensitive match on license name', () => {
      const headReport = { licenses: [{ count: 1, name: 'BSD' }], dependencies: [] };
      const baseReport = { licenses: [{ count: 1, name: 'bsd' }], dependencies: [] };
      const result = parseLicenseReportMetrics(headReport, baseReport, []);

      expect(result.length).toBe(0);
    });

    it('applies the correct approval status', () => {
      const policies = [{ id: 1, name: 'LGPL', approvalStatus: 'blacklisted' }];
      const dependency = {
        license: { name: 'lgpl', url: 'http://example.org' },
        dependency: { name: 'geoip' },
      };
      const headReport = {
        licenses: [{ count: 1, name: 'BSD' }, { count: 1, name: 'lgpl' }],
        dependencies: [dependency],
      };
      const baseReport = { licenses: [{ count: 1, name: 'bsd' }], dependencies: [] };
      const result = parseLicenseReportMetrics(headReport, baseReport, policies);

      expect(result.length).toBe(1);
      expect(result[0]).toEqual(
        jasmine.objectContaining({
          approvalStatus: 'blacklisted',
          count: 1,
          status: 'failed',
          name: 'lgpl',
          packages: [{ name: 'geoip' }],
        }),
      );
    });
  });

  describe('byLicenseNameComparator', () => {
    it('should Array sorted by of licenses by name', () => {
      const licenses = [
        { name: 'MIT' },
        { name: 'New BSD' },
        { name: 'BSD-3-Clause' },
        { name: null },
      ];

      const result = licenses.sort(byLicenseNameComparator).map(({ name }) => name);

      expect(result).toEqual([null, 'BSD-3-Clause', 'MIT', 'New BSD']);
    });
  });

  describe('normalizeLicense', () => {
    it('should convert `approval_status` to `approvalStatus`', () => {
      const src = { name: 'Foo', approval_status: 'approved', id: 3 };
      const result = normalizeLicense(src);

      expect(result.approvalStatus).toBe(src.approval_status);
      expect(result.approval_status).toBe(undefined);
      expect(result.name).toBe(src.name);
      expect(result.id).toBe(src.id);
    });
  });

  describe('getPackagesString', () => {
    const examplePackages = licenseReport[0].packages;

    it('returns string containing name of package when packages contains only one item', () => {
      expect(getPackagesString(examplePackages.slice(0, 1), true, 3)).toBe('Used by pg');
    });

    it('returns string with comma separated names of packages up to 3 when `truncate` param is true and packages count exceeds `displayPackageCount`', () => {
      expect(getPackagesString(examplePackages, true, 3)).toBe('Used by pg, puma, foo, and ');
    });

    it('returns string with comma separated names of all the packages when `truncate` param is true and packages count does NOT exceed `displayPackageCount`', () => {
      expect(getPackagesString(examplePackages.slice(0, 3), true, 3)).toBe(
        'Used by pg, puma, and foo',
      );
    });

    it('returns string with comma separated names of all the packages when `truncate` param is false irrespective of packages count', () => {
      expect(getPackagesString(examplePackages, false, 3)).toBe(
        'Used by pg, puma, foo, bar, and baz',
      );
    });
  });

  describe('getIssueStatusFromLicenseStatus', () => {
    it('returns SUCCESS status for approved license status', () => {
      expect(getIssueStatusFromLicenseStatus(LICENSE_APPROVAL_STATUS.APPROVED)).toBe(
        STATUS_SUCCESS,
      );
    });

    it('returns FAILED status for blacklisted licensens', () => {
      expect(getIssueStatusFromLicenseStatus(LICENSE_APPROVAL_STATUS.BLACKLISTED)).toBe(
        STATUS_FAILED,
      );
    });

    it('returns NEUTRAL status for undefined', () => {
      expect(getIssueStatusFromLicenseStatus()).toBe(STATUS_NEUTRAL);
    });
  });

  describe('convertToOldReportFormat', () => {
    const rawLicense = {
      name: 'license',
      classification: {
        id: 1,
        approval_status: LICENSE_APPROVAL_STATUS.APPROVED,
      },
      dependencies: [{ id: 1 }, { id: 2 }, { id: 3 }],
    };
    let parsedLicense;

    beforeEach(() => {
      parsedLicense = convertToOldReportFormat(rawLicense);
    });

    it('should get the approval status', () => {
      expect(parsedLicense.approvalStatus).toEqual(rawLicense.classification.approval_status);
    });

    it('should get the packages', () => {
      expect(parsedLicense.packages).toEqual(rawLicense.dependencies);
    });

    it('should get the id', () => {
      expect(parsedLicense.id).toEqual(rawLicense.classification.id);
    });

    it('should get the status', () => {
      expect(parsedLicense.status).toEqual(STATUS_SUCCESS);
    });

    it('should retain the license name', () => {
      expect(parsedLicense.name).toEqual(rawLicense.name);
    });
  });
});
