// eslint-disable-next-line import/prefer-default-export
export const generateFeatures = (n, overrides = {}) => {
  return [...Array(n).keys()].map(i => ({
    type: `scan-type-${i}`,
    name: `name-feature-${i}`,
    description: `description-feature-${i}`,
    link: `link-feature-${i}`,
    configuration_path: i % 2 ? `configuration_path-${i}` : null,
    configured: i % 2 === 0,
    ...overrides,
  }));
};
