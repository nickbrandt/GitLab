import { byLicenseNameComparator } from '../store/utils';

export default class V2 {
  mapFrom(report) {
    this.licenseMap = V2.createLicenseMap(report.licenses);
    this.licenses = report.licenses.sort(byLicenseNameComparator).map(V2.mapFromLicense);

    return {
      licenses: this.licenses,
      dependencies: report.dependencies.map(v2Dependency => this.mapFromDependency(v2Dependency)),
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
