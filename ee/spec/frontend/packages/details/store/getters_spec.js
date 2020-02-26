import {
  conanInstallationCommand,
  conanSetupCommand,
  packageHasPipeline,
  packageTypeDisplay,
  mavenInstallationXml,
  mavenInstallationCommand,
  mavenSetupXml,
  npmInstallationCommand,
  npmSetupCommand,
  nugetInstallationCommand,
  nugetSetupCommand,
} from 'ee/packages/details/store/getters';
import {
  conanPackage,
  npmPackage,
  nugetPackage,
  mockPipelineInfo,
  mavenPackage as packageWithoutBuildInfo,
} from '../../mock_data';
import {
  generateMavenCommand,
  generateXmlCodeBlock,
  generateMavenSetupXml,
  registryUrl,
} from '../mock_data';
import { generateConanRecipe } from 'ee/packages/details/utils';
import { NpmManager } from 'ee/packages/details/constants';

describe('Getters PackageDetails Store', () => {
  let state;

  const mockPipelineError = 'mock-pipeline-error';

  const defaultState = {
    packageEntity: packageWithoutBuildInfo,
    pipelineInfo: mockPipelineInfo,
    pipelineError: mockPipelineError,
    conanPath: registryUrl,
    mavenPath: registryUrl,
    npmPath: registryUrl,
    nugetPath: registryUrl,
  };

  const setupState = (testState = {}) => {
    state = {
      ...defaultState,
      ...testState,
    };
  };

  const recipe = generateConanRecipe(conanPackage);
  const conanInstallationCommandStr = `conan install ${recipe} --remote=gitlab`;
  const conanSetupCommandStr = `conan remote add gitlab ${registryUrl}`;

  const mavenCommandStr = generateMavenCommand(packageWithoutBuildInfo.maven_metadatum);
  const mavenInstallationXmlBlock = generateXmlCodeBlock(packageWithoutBuildInfo.maven_metadatum);
  const mavenSetupXmlBlock = generateMavenSetupXml();

  const npmInstallStr = `npm i ${npmPackage.name}`;
  const npmSetupStr = `echo @Test:registry=${registryUrl} >> .npmrc`;
  const yarnInstallStr = `yarn add ${npmPackage.name}`;
  const yarnSetupStr = `echo \\"@Test:registry\\" \\"${registryUrl}\\" >> .yarnrc`;

  const nugetInstallationCommandStr = `nuget install ${nugetPackage.name} -Source "GitLab"`;
  const nugetSetupCommandStr = `nuget source Add -Name "GitLab" -Source "${registryUrl}" -UserName <your_username> -Password <your_token>`;

  describe('packageHasPipeline', () => {
    it('should return true when build_info and pipeline_id exist', () => {
      setupState({
        packageEntity: npmPackage,
      });

      expect(packageHasPipeline(state)).toEqual(true);
    });

    it('should return false when build_info does not exist', () => {
      setupState();

      expect(packageHasPipeline(state)).toEqual(false);
    });
  });

  describe('packageTypeDisplay', () => {
    describe.each`
      packageEntity              | expectedResult
      ${conanPackage}            | ${'Conan'}
      ${packageWithoutBuildInfo} | ${'Maven'}
      ${npmPackage}              | ${'NPM'}
      ${nugetPackage}            | ${'NuGet'}
    `(`package type`, ({ packageEntity, expectedResult }) => {
      beforeEach(() => setupState({ packageEntity }));

      it(`${packageEntity.package_type} should show as ${expectedResult}`, () => {
        expect(packageTypeDisplay(state)).toBe(expectedResult);
      });
    });
  });

  describe('conan string getters', () => {
    it('gets the correct conanInstallationCommand', () => {
      setupState({ packageEntity: conanPackage });

      expect(conanInstallationCommand(state)).toEqual(conanInstallationCommandStr);
    });

    it('gets the correct conanSetupCommand', () => {
      setupState({ packageEntity: conanPackage });

      expect(conanSetupCommand(state)).toEqual(conanSetupCommandStr);
    });
  });

  describe('maven string getters', () => {
    it('gets the correct mavenInstallationXml', () => {
      setupState();

      expect(mavenInstallationXml(state)).toEqual(mavenInstallationXmlBlock);
    });

    it('gets the correct mavenInstallationCommand', () => {
      setupState();

      expect(mavenInstallationCommand(state)).toEqual(mavenCommandStr);
    });

    it('gets the correct mavenSetupXml', () => {
      setupState();

      expect(mavenSetupXml(state)).toEqual(mavenSetupXmlBlock);
    });
  });

  describe('npm string getters', () => {
    it('gets the correct npmInstallationCommand for NPM', () => {
      setupState({ packageEntity: npmPackage });

      expect(npmInstallationCommand(state)(NpmManager.NPM)).toEqual(npmInstallStr);
    });

    it('gets the correct npmSetupCommand for NPM', () => {
      setupState({ packageEntity: npmPackage });

      expect(npmSetupCommand(state)(NpmManager.NPM)).toEqual(npmSetupStr);
    });

    it('gets the correct npmInstallationCommand for Yarn', () => {
      setupState({ packageEntity: npmPackage });

      expect(npmInstallationCommand(state)(NpmManager.YARN)).toEqual(yarnInstallStr);
    });

    it('gets the correct npmSetupCommand for Yarn', () => {
      setupState({ packageEntity: npmPackage });

      expect(npmSetupCommand(state)(NpmManager.YARN)).toEqual(yarnSetupStr);
    });
  });

  describe('nuget string getters', () => {
    it('gets the correct nugetInstallationCommand', () => {
      setupState({ packageEntity: nugetPackage });

      expect(nugetInstallationCommand(state)).toEqual(nugetInstallationCommandStr);
    });

    it('gets the correct nugetSetupCommand', () => {
      setupState({ packageEntity: nugetPackage });

      expect(nugetSetupCommand(state)).toEqual(nugetSetupCommandStr);
    });
  });
});
