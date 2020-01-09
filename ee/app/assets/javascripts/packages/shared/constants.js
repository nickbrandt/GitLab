export const PackageType = {
  MAVEN: 'maven',
  NPM: 'npm',
  CONAN: 'conan',
};

export const TrackingActions = {
  DELETE_PACKAGE: 'delete_package',
  PULL_PACKAGE: 'pull_package',
};

export const TrackingCategories = {
  [PackageType.MAVEN]: 'MavenPackages',
  [PackageType.NPM]: 'NpmPackages',
  [PackageType.CONAN]: 'ConanPackages',
};
