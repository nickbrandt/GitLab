import * as getters from 'ee/approvals/stores/modules/base/getters';

describe('EE store modules base getters', () => {
  describe('isEmpty', () => {
    it('when rules is falsey, is true', () => {
      expect(getters.isEmpty({})).toBe(true);
    });

    it('when rules is empty, is true', () => {
      expect(getters.isEmpty({ rules: [] })).toBe(true);
    });

    it('when rules has items, is false', () => {
      expect(getters.isEmpty({ rules: [1] })).toBe(false);
    });
  });
});
