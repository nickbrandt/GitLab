import STORAGE_KEY from './constants';

/**
 * onboarding_state:
 * activeTour: Number
 * dismissed: Boolean
 */

const ONBOARDING_PROPS_DEFAULTS = {
  activeTourKey: 1,
  dismissed: false,
};

export const resetOnboardingLocalStorage = () => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(ONBOARDING_PROPS_DEFAULTS));
};

export const getOnboardingLocalStorageState = () => JSON.parse(localStorage.getItem(STORAGE_KEY));

export const updateLocalStorage = updatedProps => {
  let currentState = getOnboardingLocalStorageState();

  if (!currentState) {
    currentState = resetOnboardingLocalStorage();
  }

  const onboardingState = {
    ...currentState,
    ...updatedProps,
  };

  localStorage.setItem(STORAGE_KEY, JSON.stringify(onboardingState));
};
