import Cookies from 'js-cookie';
import AccessorUtilities from '~/lib/utils/accessor';
import {
  ONBOARDING_DISMISSED_COOKIE_NAME,
  STORAGE_KEY,
  ONBOARDING_PROPS_DEFAULTS,
} from './constants';

const isOnboardingDismissed = () => Cookies.get(ONBOARDING_DISMISSED_COOKIE_NAME) === 'true';

const updateOnboardingDismissed = dismissed => {
  Cookies.set(ONBOARDING_DISMISSED_COOKIE_NAME, dismissed);

  if (dismissed && AccessorUtilities.isLocalStorageAccessSafe()) {
    localStorage.removeItem(STORAGE_KEY);
  }
};

const resetOnboardingLocalStorage = () => {
  if (AccessorUtilities.isLocalStorageAccessSafe()) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(ONBOARDING_PROPS_DEFAULTS));
  }
};

const getOnboardingLocalStorageState = () => {
  if (AccessorUtilities.isLocalStorageAccessSafe()) {
    return JSON.parse(localStorage.getItem(STORAGE_KEY));
  }

  return ONBOARDING_PROPS_DEFAULTS;
};

const updateLocalStorage = updatedProps => {
  if (AccessorUtilities.isLocalStorageAccessSafe()) {
    let currentState = getOnboardingLocalStorageState();

    if (!currentState) {
      currentState = resetOnboardingLocalStorage();
    }

    const onboardingState = {
      ...currentState,
      ...updatedProps,
    };

    localStorage.setItem(STORAGE_KEY, JSON.stringify(onboardingState));
  }
};

const onboardingUtils = {
  isOnboardingDismissed,
  updateOnboardingDismissed,
  resetOnboardingLocalStorage,
  getOnboardingLocalStorageState,
  updateLocalStorage,
};

export default onboardingUtils;
