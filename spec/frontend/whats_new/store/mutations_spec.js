import mutations from '~/whats_new/store/mutations';
import createState from '~/whats_new/store/state';

describe('whats new mutations', () => {
  let state;

  beforeEach(() => {
    state = createState;
  });

  describe('openDrawer', () => {
    it('sets open to true', () => {
      mutations.openDrawer(state);
      expect(state.open).toBe(true);
    });
  });

  describe('closeDrawer', () => {
    it('sets open to false', () => {
      mutations.closeDrawer(state);
      expect(state.open).toBe(false);
    });
  });
});
