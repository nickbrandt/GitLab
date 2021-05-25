import { augmentFeatures } from '~/security_configuration/utils';

const mockSecurityFeatures = [
  {
    name: 'SAST',
    type: 'SAST',
  },
];

const mockComplianceFeatures = [
  {
    name: 'LICENSE_COMPLIANCE',
    type: 'LICENSE_COMPLIANCE',
  },
];

const mockFeaturesWithSecondary = [
  {
    name: 'DAST',
    type: 'DAST',
    secondary: {
      type: 'DAST PROFILES',
      name: 'DAST PROFILES',
    },
  },
];

const mockInvalidCustomFeature = [
  {
    foo: 'bar',
  },
];

const mockValidCustomFeature = [
  {
    name: 'SAST',
    type: 'SAST',
    customfield: 'customvalue',
  },
];

const expectedOutputDefault = {
  augmentedSecurityFeatures: mockSecurityFeatures,
  augmentedComplianceFeatures: mockComplianceFeatures,
};

const expectedOutputSecondary = {
  augmentedSecurityFeatures: mockSecurityFeatures,
  augmentedComplianceFeatures: mockFeaturesWithSecondary,
};

const expectedOutputCustomFeature = {
  augmentedSecurityFeatures: mockValidCustomFeature,
  augmentedComplianceFeatures: mockComplianceFeatures,
};

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
