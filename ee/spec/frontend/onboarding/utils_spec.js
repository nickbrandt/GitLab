import Cookies from 'js-cookie';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import {
  ONBOARDING_DISMISSED_COOKIE_NAME,
  STORAGE_KEY,
  ONBOARDING_PROPS_DEFAULTS,
} from 'ee/onboarding/constants';
import onboardingUtils from 'ee/onboarding/utils';
import AccessorUtilities from '~/lib/utils/accessor';

describe('User onboarding utils', () => {
  useLocalStorageSpy();

  beforeEach(() => {
    Cookies.remove(ONBOARDING_DISMISSED_COOKIE_NAME);
    onboardingUtils.resetOnboardingLocalStorage();
    jest.spyOn(AccessorUtilities, 'isLocalStorageAccessSafe').mockReturnValue(true);
  });

  describe('isOnboardingDismissed', () => {
    it('return true if the cookie value is true', () => {
      Cookies.set(ONBOARDING_DISMISSED_COOKIE_NAME, true);

      expect(onboardingUtils.isOnboardingDismissed()).toBe(true);
    });

    it('return false if the cookie is not set', () => {
      expect(onboardingUtils.isOnboardingDismissed()).toBe(false);
    });
  });

  describe('updateOnboardingDismissed', () => {
    it('set the dismissed state on the cookie', () => {
      onboardingUtils.updateOnboardingDismissed(true);

      expect(Cookies.get(ONBOARDING_DISMISSED_COOKIE_NAME)).toBe('true');
    });

    it('removes onboarding related data from localStorage', () => {
      onboardingUtils.updateOnboardingDismissed(true);

      expect(localStorage.removeItem).toHaveBeenCalledWith(STORAGE_KEY);
    });
  });

  describe('resetOnboardingLocalStorage', () => {
    it('resets the onboarding props in the localStorage to the default', () => {
      jest.spyOn(window.localStorage, 'setItem');
      onboardingUtils.resetOnboardingLocalStorage();
      expect(localStorage.setItem).toHaveBeenCalledWith(
        STORAGE_KEY,
        JSON.stringify(ONBOARDING_PROPS_DEFAULTS),
      );
    });
  });

  describe('getOnboardingLocalStorageState', () => {
    it('retrieves the proper values from localStorage', () => {
      jest.spyOn(window.localStorage, 'getItem').mockReturnValue('{}');
      onboardingUtils.getOnboardingLocalStorageState();
      expect(localStorage.getItem).toHaveBeenCalledWith(STORAGE_KEY);
    });
  });

  describe('updateLocalStorage', () => {
    it('updates the onboarding state on the localStorage', () => {
      jest.spyOn(window.localStorage, 'getItem').mockReturnValue('{}');
      jest.spyOn(window.localStorage, 'setItem');
      const modified = {
        tourKey: 2,
        lastStepIndex: 5,
        createdProjectPath: 'foo',
      };
      onboardingUtils.updateLocalStorage(modified);
      expect(localStorage.setItem).toHaveBeenCalledWith(STORAGE_KEY, JSON.stringify(modified));
    });
  });
});
