import { s__, sprintf } from '~/locale';

export const ONBOARDING_DISMISSED_COOKIE_NAME = 'onboarding_dismissed';

export const STORAGE_KEY = 'onboarding_state';

export const AVAILABLE_TOURS = {
  GUIDED_GITLAB_TOUR: 1,
  CREATE_PROJECT_TOUR: 2,
  INVITE_COLLEAGUES_TOUR: 3,
};

export const TOUR_TITLES = [
  { id: AVAILABLE_TOURS.GUIDED_GITLAB_TOUR, title: s__('UserOnboardingTour|Guided GitLab Tour') },
  { id: AVAILABLE_TOURS.CREATE_PROJECT_TOUR, title: s__('UserOnboardingTour|Create a project') },
  {
    id: AVAILABLE_TOURS.INVITE_COLLEAGUES_TOUR,
    title: s__('UserOnboardingTour|Invite colleagues'),
  },
];

export const ONBOARDING_PROPS_DEFAULTS = {
  tourKey: AVAILABLE_TOURS.GUIDED_GITLAB_TOUR,
  lastStepIndex: -1,
  createdProjectPath: '',
};

export const ACCEPTING_MR_LABEL_TEXT = 'Accepting merge requests';

export const LABEL_SEARCH_QUERY = `scope=all&state=opened&label_name[]=${encodeURIComponent(
  ACCEPTING_MR_LABEL_TEXT,
)}`;

export const EXIT_TOUR_CONTENT = {
  text: sprintf(
    s__(
      'UserOnboardingTour|Thanks for taking the guided tour. Remember, if you want to go through it again, you can start %{emphasisStart}Learn GitLab%{emphasisEnd} in the help menu on the top right.',
    ),
    {
      emphasisStart: '<strong>',
      emphasisEnd: '</strong>',
    },
    false,
  ),
  buttons: [{ text: s__('UserOnboardingTour|Got it'), btnClass: 'btn-primary', exitTour: true }],
};
