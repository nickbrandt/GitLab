import AccessorUtilities from '~/lib/utils/accessor';
import {
  STORAGE_KEY,
  hasSeenTopNav,
  setSeenTopNav,
  isAvailable,
} from '~/nav/utils/has_seen_top_nav';

describe('~/nav/utils/has_seen_top_nav', () => {
  beforeEach(() => {
    isAvailable.cache.clear();
    localStorage.clear();
  });

  describe('default', () => {
    beforeEach(() => {
      jest.spyOn(AccessorUtilities, 'isLocalStorageAccessSafe').mockReturnValue(true);
    });

    it('hasSeenTopNav returns false', () => {
      expect(hasSeenTopNav()).toBe(false);
    });

    it('has no local storage', () => {
      expect(localStorage.getItem(STORAGE_KEY)).toBeNull();
    });

    describe('when setSeenTopNav is called', () => {
      beforeEach(() => {
        setSeenTopNav();
      });

      it('sets local storage', () => {
        expect(localStorage.getItem(STORAGE_KEY)).toBe('1');
      });

      it('hasSeenTopNav returns true', () => {
        expect(hasSeenTopNav()).toBe(true);
      });
    });
  });

  describe('when cannot use local storage', () => {
    beforeEach(() => {
      jest.spyOn(AccessorUtilities, 'isLocalStorageAccessSafe').mockReturnValue(false);
    });

    it('hasSeenTopNav returns false', () => {
      expect(hasSeenTopNav()).toBe(false);
    });

    it('setSeenTopNav does nothing', () => {
      setSeenTopNav();

      expect(localStorage.getItem(STORAGE_KEY)).toBeNull();
    });
  });
});
