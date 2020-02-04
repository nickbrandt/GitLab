import { packageHasPipeline, packageTypeDisplay } from 'ee/packages/details/store/getters';
import {
  conanPackage,
  npmPackage,
  nugetPackage,
  mockPipelineInfo,
  mavenPackage as packageWithoutBuildInfo,
} from '../../mock_data';

describe('Getters PackageDetails Store', () => {
  let state;

  const mockPipelineError = 'mock-pipeline-error';

  const defaultState = {
    packageEntity: packageWithoutBuildInfo,
    pipelineInfo: mockPipelineInfo,
    pipelineError: mockPipelineError,
  };

  const setupState = (testState = defaultState) => {
    state = testState;
  };

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
});
