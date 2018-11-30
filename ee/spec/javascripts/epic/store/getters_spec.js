import * as getters from 'ee/epic/store/getters';
import { statusType } from 'ee/epic/constants';

describe('Epic Store Getters', () => {
  describe('isEpicOpen', () => {
    it('returns `true` when Epic `state` is `opened`', () => {
      const epicState = {
        state: statusType.open,
      };

      expect(getters.isEpicOpen(epicState)).toBe(true);
    });

    it('returns `false` when Epic `state` is `closed`', () => {
      const epicState = {
        state: statusType.closed,
      };

      expect(getters.isEpicOpen(epicState)).toBe(false);
    });
  });
});
