export const mavenPackage = {
  created_at: '',
  id: 1,
  maven_metadatum: {
    app_group: 'com.test.app',
    app_name: 'test-app',
    app_version: '1.0-SNAPSHOT',
  },
  name: 'Test package',
  package_type: 'maven',
  project_id: 1,
  updated_at: '',
  version: '1.0.0',
};

export const mavenFiles = [
  {
    created_at: '',
    file_name: 'File one',
    id: 1,
    size: 100,
    download_path: '/-/package_files/1/download',
  },
  {
    created_at: '',
    file_name: 'File two',
    id: 2,
    size: 200,
    download_path: '/-/package_files/2/download',
  },
];

export const npmPackage = {
  created_at: '',
  id: 2,
  name: '@Test/package',
  package_type: 'npm',
  project_id: 1,
  updated_at: '',
  version: '',
};

export const npmFiles = [
  {
    created_at: '',
    file_name: '@test/test-package-1.0.0.tgz',
    id: 2,
    size: 200,
    download_path: '/-/package_files/2/download',
  },
];

export const conanPackage = {
  conan_metadatum: {
    package_channel: 'stable',
    package_username: 'conan+conan-package',
  },
  created_at: '',
  id: 3,
  name: 'conan-package',
  package_files: [],
  package_type: 'conan',
  project_id: 1,
  recipe: 'conan-package/1.0.0@conan+conan-package/stable',
  updated_at: '',
  version: '1.0.0',
};

export const packageList = [mavenPackage, npmPackage, conanPackage];
