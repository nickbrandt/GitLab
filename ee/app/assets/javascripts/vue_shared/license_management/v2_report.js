import { byLicenseNameComparator } from './store/utils';
import { VERSION_1_1 } from './constants';

export default class V2Report {
  constructor(report) {
    this.report = report;
    this.licenseMap = V2Report.createLicenseMap(report.licenses);
    this.licenses = report.licenses.sort(byLicenseNameComparator).map(V2Report.mapFromLicense);
  }

  toV1Schema() {
    return {
      version: VERSION_1_1,
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

  mapFromDependency({ name, description, url, licenses }) {
    const convertedLicenses = [];
    const combinedLicense = this.combine(licenses, license => {
      this.incrementCountFor(license.name);
      convertedLicenses.push(license);
    });

    return {
      license: combinedLicense,
      licenses: convertedLicenses,
      dependency: { name, url, description },
    };
  }

  static mapFromLicense({ name, url = '', count = 0 }) {
    return { name, url, count };
  }

  static createLicenseMap(licenses) {
    const identityMap = {};
    licenses.forEach(item => {
      identityMap[item.id] = {
        name: item.name,
        url: item.url,
      };
    });
    return identityMap;
  }
}
