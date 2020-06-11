import { getParentPaths } from '~/ide/stores/modules/file_system/utils/path';

describe('~/ide/stores/modules/file_system/utils/path', () => {
  describe('getParentPaths', () => {
    it.each`
      input                | output
      ${'config'}          | ${[]}
      ${'config/test'}     | ${['config']}
      ${'config/test/123'} | ${['config', 'config/test']}
    `('works with $input', ({ input, output }) => {
      expect(getParentPaths(input)).toEqual(output);
    });
  });
});
