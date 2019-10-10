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

  combine(licenses) {
    return licenses.reduce(
      (memo, licenseId) => {
        const license = this.licenseMap[licenseId];
        this.incrementCountFor(license.name);

        if (memo.name === null) {
          return {
            name: license.name,
            url: license.url,
          };
        }
        return { name: `${memo.name}, ${license.name}`, url: '' };
      },
      { name: null, url: null },
    );
  }

  incrementCountFor(licenseName) {
    const legacyLicense = this.licenses.find(license => license.name === licenseName);
    if (legacyLicense) legacyLicense.count += 1;
  }

  mapFromDependency(dependency) {
    return {
      license: this.combine(dependency.licenses),
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
    return licenses.reduce((memo, item) => {
      memo[item.id] = { name: item.name, url: item.url }; // eslint-disable-line no-param-reassign
      return memo;
    }, {});
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
