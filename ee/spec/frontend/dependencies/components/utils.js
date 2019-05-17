// eslint-disable-next-line import/prefer-default-export
export const makeDependency = (changes = {}) => ({
  name: 'left-pad',
  version: '0.0.3',
  type: 'npm',
  location: { blob_path: 'yarn.lock' },
  ...changes,
});
