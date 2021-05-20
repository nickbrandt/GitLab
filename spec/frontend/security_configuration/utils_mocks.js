export const mockSecurityFeatures = [
  {
    name: 'SAST',
    type: 'SAST',
  },
];

export const mockComplianceFeatures = [
  {
    name: 'LICENSE_COMPLIANCE',
    type: 'LICENSE_COMPLIANCE',
  },
];

export const mockFeaturesWithSecondary = [
  {
    name: 'DAST',
    type: 'DAST',
    secondary: {
      type: 'DAST PROFILES',
      name: 'DAST PROFILES',
    },
  },
];

export const mockInvalidCustomFeature = [
  {
    foo: 'bar',
  },
];

export const mockValidCustomFeature = [
  {
    name: 'SAST',
    type: 'SAST',
    customfield: 'customvalue',
  },
];

export const expectedOutputDefault = {
  augmentedSecurityFeatures: mockSecurityFeatures,
  augmentedComplianceFeatures: mockComplianceFeatures,
};

export const expectedOutputSecondary = {
  augmentedSecurityFeatures: mockSecurityFeatures,
  augmentedComplianceFeatures: mockFeaturesWithSecondary,
};

export const expectedOutputCustomFeature = {
  augmentedSecurityFeatures: mockValidCustomFeature,
  augmentedComplianceFeatures: mockComplianceFeatures,
};
