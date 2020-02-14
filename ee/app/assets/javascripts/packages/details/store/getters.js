import { s__ } from '~/locale';
import { generateConanRecipe } from '../utils';

export const packageHasPipeline = ({ packageEntity }) => {
  if (packageEntity?.build_info?.pipeline_id) {
    return true;
  }

  return false;
};

export const packageTypeDisplay = ({ packageEntity }) => {
  switch (packageEntity.package_type) {
    case 'conan':
      return s__('PackageType|Conan');
    case 'maven':
      return s__('PackageType|Maven');
    case 'npm':
      return s__('PackageType|NPM');
    case 'nuget':
      return s__('PackageType|NuGet');

    default:
      return null;
  }
};

export const conanInstallationCommand = ({ packageEntity }) => {
  const recipe = generateConanRecipe(packageEntity);

  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  return `conan install ${recipe} --remote=gitlab`;
};

export const conanSetupCommand = ({ conanPath }) =>
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  `conan remote add gitlab ${conanPath}`;

export const mavenInstallationXml = ({ packageEntity = {} }) => {
  const {
    app_group: appGroup = '',
    app_name: appName = '',
    app_version: appVersion = '',
  } = packageEntity.maven_metadatum;

  return `<dependency>
  <groupId>${appGroup}</groupId>
  <artifactId>${appName}</artifactId>
  <version>${appVersion}</version>
</dependency>`;
};

export const mavenInstallationCommand = ({ packageEntity = {} }) => {
  const {
    app_group: group = '',
    app_name: name = '',
    app_version: version = '',
  } = packageEntity.maven_metadatum;

  return `mvn dependency:get -Dartifact=${group}:${name}:${version}`;
};

export const mavenSetupXml = ({ mavenPath }) => `<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>${mavenPath}</url>
  </repository>
</repositories>

<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>${mavenPath}</url>
  </repository>

  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>${mavenPath}</url>
  </snapshotRepository>
</distributionManagement>`;

export const nugetInstallationCommand = ({ packageEntity }) =>
  `nuget install ${packageEntity.name} -Source "GitLab"`;

export const nugetSetupCommand = ({ nugetPath }) =>
  `nuget source Add -Name "GitLab" -Source "${nugetPath}" -UserName <your_username> -Password <your_token>`;
