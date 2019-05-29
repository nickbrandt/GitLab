export const ONBOARDING_DISMISSED_COOKIE_NAME = 'onboarding_dismissed';

export const STORAGE_KEY = 'onboarding_state';

export const AVAILABLE_TOURS = {
  GUIDED_GITLAB_TOUR: 1,
  CREATE_PROJECT_TOUR: 2,
  INVITE_COLLEAGUES_TOUR: 3,
};

export const ONBOARDING_PROPS_DEFAULTS = {
  tourKey: AVAILABLE_TOURS.GUIDED_GITLAB_TOUR,
  lastStepIndex: -1,
  createdProjectPath: '',
};
