import { augmentFeatures } from '~/security_configuration/utils';
import {
  mockSecurityFeatures,
  mockComplianceFeatures,
  mockFeaturesWithSecondary,
  mockInvalidCustomFeature,
  mockValidCustomFeature,
  expectedOutputCustomFeature,
  expectedOutputDefault,
  expectedOutputSecondary,
} from './utils_mocks';

describe('augmentFeatures', () => {
  it('augments features array correctly when given an empty array', () => {
    expect(augmentFeatures(mockSecurityFeatures, mockComplianceFeatures, [])).toEqual(
      expectedOutputDefault,
    );
  });

  it('augments features array correctly when given an invalid populated array', () => {
    expect(
      augmentFeatures(mockSecurityFeatures, mockComplianceFeatures, mockInvalidCustomFeature),
    ).toEqual(expectedOutputDefault);
  });

  it('augments features array correctly when features have secondary key', () => {
    expect(augmentFeatures(mockSecurityFeatures, mockFeaturesWithSecondary, [])).toEqual(
      expectedOutputSecondary,
    );
  });

  it('augments features array correctly when given a valid populated array', () => {
    expect(
      augmentFeatures(mockSecurityFeatures, mockComplianceFeatures, mockValidCustomFeature),
    ).toEqual(expectedOutputCustomFeature);
  });
});
