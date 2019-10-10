import { byLicenseNameComparator } from './store/utils';

class V2Report {
  constructor(report) {
    this.report = report;
    this.licenseMap = V2Report.createLicenseMap(report.licenses);
    this.licenses = report.licenses.sort(byLicenseNameComparator).map(V2Report.mapFromLicense);
  }

  toV1Schema() {
    return {
      licenses: this.licenses,
      dependencies: this.report.dependencies.map(v2Dependency =>
        this.mapFromDependency(v2Dependency),
      ),
    };
  }

  combine(licenses, visitor) {
    const reducer = (memo, licenseId) => {
      const license = this.licenseMap[licenseId];
      visitor(license);
      if (memo) return { name: `${memo.name}, ${license.name}`, url: '' };
      return { name: license.name, url: license.url };
    };

    return licenses.reduce(reducer, null);
  }

  incrementCountFor(licenseName) {
    const matchingLicense = this.licenses.find(license => license.name === licenseName);
    if (matchingLicense) matchingLicense.count += 1;
  }

  mapFromDependency(dependency) {
    const combinedLicense = this.combine(dependency.licenses, license => {
      this.incrementCountFor(license.name);
    });

    return {
      license: combinedLicense,
      dependency: {
        name: dependency.name,
        url: dependency.url,
        description: dependency.description,
      },
    };
  }

  static mapFromLicense(license) {
    return { name: license.name, count: 0 };
  }

  static createLicenseMap(licenses) {
    const reducer = (memo, item) => {
      memo[item.id] = { name: item.name, url: item.url }; // eslint-disable-line no-param-reassign
      return memo;
    };
    return licenses.reduce(reducer, {});
  }
}

const DEFAULT_VERSION = '1';

export default class ReportMapper {
  constructor() {
    this.mappers = {
      '1': report => report,
      '2': report => new V2Report(report).toV1Schema(),
    };
  }

  mapFrom(reportArtifact) {
    const majorVersion = ReportMapper.majorVersion(reportArtifact);
    return this.mapperFor(majorVersion)(reportArtifact);
  }

  mapperFor(majorVersion) {
    return this.mappers[majorVersion];
  }

  static majorVersion(report) {
    return report && report.version ? report.version.split('.')[0] : DEFAULT_VERSION;
  }
}
