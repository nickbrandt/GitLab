import * as getters from 'ee/packages/list/stores/getters';
import { packageList } from '../../mock_data';

describe('Getters registry list store', () => {
  const state = {
    packages: packageList,
  };
  describe('getList', () => {
    const result = getters.getList(state);
    it('returns a list of packages', () => {
      expect(result).toHaveLength(packageList.length);
      expect(result[0].name).toBe('Test package');
    });
    it('adds projectPathName', () => {
      expect(result[0].projectPathName).toMatchInlineSnapshot(`"foo / bar / baz"`);
    });
  });
});
